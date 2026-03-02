import Foundation
import Combine

@MainActor
final class BrewViewModel: ObservableObject {
    @Published var installedFormulae: [BrewPackage] = []
    @Published var installedCasks: [BrewPackage] = []
    @Published var sidebarKind: BrewPackageKind = .formula
    @Published var discoverResults: [BrewPackage] = []
    @Published var sidebarQuery = ""
    @Published var discoverQuery = ""
    @Published var discoverKind: BrewPackageKind = .formula
    @Published var selectedPackage: BrewPackage?

    @Published var outdatedCount = 0
    @Published var outdatedPackageNames: Set<String> = []
    @Published var tapCount = 0
    @Published var analyticsEnabled = true

    @Published var status = "Ready"
    @Published var lastOutput = ""
    @Published var isBusy = false
    @Published var errorMessage = ""

    private let service = BrewService()

    var totalInstalledCount: Int {
        installedFormulae.count + installedCasks.count
    }

    var allInstalledSorted: [BrewPackage] {
        (installedFormulae + installedCasks).sorted { $0.name < $1.name }
    }

    var filteredInstalled: [BrewPackage] {
        let source: [BrewPackage]
        switch sidebarKind {
        case .formula:
            source = installedFormulae
        case .cask:
            source = installedCasks
        }

        let sortedSource = source.sorted { $0.name < $1.name }
        let query = sidebarQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return sortedSource
        }

        return sortedSource.filter {
            $0.name.lowercased().contains(query) || $0.version.lowercased().contains(query)
        }
    }

    func bootstrap() {
        Task {
            await refreshDashboard()
        }
    }

    func refreshDashboard() async {
        await runBusyTask("Refreshing Homebrew status...") {
            try await service.ensureBrewAvailable()

            async let formulae = service.listInstalled(kind: .formula)
            async let casks = service.listInstalled(kind: .cask)
            async let outdated = service.outdatedPackageNames()
            async let taps = service.tapCount()
            async let analytics = service.analyticsEnabled()

            let loadedFormulae = try await formulae
            let loadedCasks = try await casks
            let loadedOutdated = try await outdated
            let loadedTaps = try await taps
            let loadedAnalytics = try await analytics

            installedFormulae = loadedFormulae
            installedCasks = loadedCasks
            outdatedPackageNames = loadedOutdated
            outdatedCount = loadedOutdated.count
            tapCount = loadedTaps
            analyticsEnabled = loadedAnalytics

            if let selected = selectedPackage {
                selectedPackage = allInstalledSorted.first(where: { $0.id == selected.id })
            }

            status = "Loaded \(totalInstalledCount) packages."
        }
    }

    func searchCatalog() async {
        let localQuery = discoverQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !localQuery.isEmpty else {
            discoverResults = []
            status = "Enter package name to search."
            return
        }

        await runBusyTask("Searching \(discoverKind.title.lowercased()) for \"\(localQuery)\"...") {
            discoverResults = try await service.search(kind: discoverKind, query: localQuery)
            status = "Found \(discoverResults.count) packages."
        }
    }

    func install(_ package: BrewPackage) async {
        let alreadyInstalled = isInstalled(package)

        await runBusyTask("\(alreadyInstalled ? "Reinstalling" : "Installing") \(package.name)...") {
            let output: String
            if alreadyInstalled {
                output = try await service.reinstall(name: package.name, kind: package.kind)
            } else {
                output = try await service.install(name: package.name, kind: package.kind)
            }

            lastOutput = output
            status = "\(alreadyInstalled ? "Reinstalled" : "Installed") \(package.name)."
            try await refreshDashboardDataOnly()
        }
    }

    func uninstall(_ package: BrewPackage) async {
        await runBusyTask("Uninstalling \(package.name)...") {
            let output = try await service.uninstall(name: package.name, kind: package.kind)
            lastOutput = output
            status = "Uninstalled \(package.name)."
            try await refreshDashboardDataOnly()
            if selectedPackage?.id == package.id {
                selectedPackage = nil
            }
        }
    }

    func runUpdate() async {
        await runBusyTask("Running brew update...") {
            lastOutput = try await service.updateMetadata()
            status = "Updated Homebrew metadata."
            try await refreshDashboardDataOnly()
        }
    }

    func runUpgrade() async {
        await runBusyTask("Running brew upgrade...") {
            lastOutput = try await service.upgradeOutdated()
            status = "Upgrade complete."
            try await refreshDashboardDataOnly()
        }
    }

    func isInstalled(_ package: BrewPackage) -> Bool {
        allInstalledSorted.contains(where: { $0.name == package.name && $0.kind == package.kind })
    }

    func hasUpdate(_ package: BrewPackage) -> Bool {
        outdatedPackageNames.contains(package.name)
    }

    private func refreshDashboardDataOnly() async throws {
        async let formulae = service.listInstalled(kind: .formula)
        async let casks = service.listInstalled(kind: .cask)
        async let outdated = service.outdatedPackageNames()
        async let taps = service.tapCount()
        async let analytics = service.analyticsEnabled()

        installedFormulae = try await formulae
        installedCasks = try await casks
        outdatedPackageNames = try await outdated
        outdatedCount = outdatedPackageNames.count
        tapCount = try await taps
        analyticsEnabled = try await analytics
    }

    private func runBusyTask(_ message: String, _ task: () async throws -> Void) async {
        guard !isBusy else { return }

        isBusy = true
        errorMessage = ""
        status = message

        do {
            try await task()
        } catch {
            errorMessage = error.localizedDescription
            status = "Failed"
        }

        isBusy = false
    }
}
