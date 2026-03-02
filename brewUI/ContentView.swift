import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BrewViewModel()
    private enum TypeScale {
        static let statusTitle: CGFloat = 18
        static let statusSubtitle: CGFloat = 13
        static let metricTitle: CGFloat = 16
        static let metricSubtitle: CGFloat = 12
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            mainDashboard
        }
        .frame(minWidth: 1180, minHeight: 760)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            viewModel.bootstrap()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Packages", selection: $viewModel.sidebarKind) {
                Text("Formulae").tag(BrewPackageKind.formula)
                Text("Casks").tag(BrewPackageKind.cask)
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Installed Packages", text: $viewModel.sidebarQuery)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("Installed \(viewModel.sidebarKind.title)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)

            List(viewModel.filteredInstalled, selection: $viewModel.selectedPackage) { package in
                HStack(spacing: 10) {
                    if viewModel.hasUpdate(package) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                    } else {
                        Color.clear
                            .frame(width: 8, height: 8)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(package.name)
                            .font(.system(size: 16, weight: .medium))
                        Text(package.version.isEmpty ? package.kind.title : package.version)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .tag(package)
            }
            .listStyle(.plain)
        }
        .padding(18)
        .frame(width: 320)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))
    }

    private var mainDashboard: some View {
        VStack(alignment: .leading, spacing: 16) {
            topBar
            statusLine

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    outdatedCard
                    catalogCard
                    countsCard
                    selectedPackageCard
                }
                .padding(.bottom, 14)
            }
        }
        .padding(22)
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            HStack(alignment: .top, spacing: 12) {
                Image("BrewLogo")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("brewUI")
                        .font(.system(size: 30, weight: .bold))
                    Text("\(viewModel.totalInstalledCount) packages installed")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text("Made for developers")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                iconButton(systemName: "arrow.down.circle", helpText: "Update metadata and upgrade outdated packages") {
                    Task { await viewModel.runUpdate() }
                }

                iconButton(systemName: "arrow.clockwise", helpText: "Refresh package status") {
                    Task { await viewModel.refreshDashboard() }
                }

                iconButton(systemName: "arrow.triangle.2.circlepath.circle", helpText: "Upgrade outdated packages") {
                    Task { await viewModel.runUpgrade() }
                }
            }
        }
    }

    private var outdatedCard: some View {
        statusCard(icon: "arrow.down.circle", title: "There are \(viewModel.outdatedCount) outdated packages", subtitle: "Outdated packages") {
            Button("Update") {
                Task { await viewModel.runUpdate() }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isBusy)
        }
    }

    private var statusLine: some View {
        HStack {
            if viewModel.isBusy {
                ProgressView()
                    .controlSize(.small)
            }
            Text(viewModel.errorMessage.isEmpty ? viewModel.status : viewModel.errorMessage)
                .font(.system(size: 12))
                .foregroundColor(viewModel.errorMessage.isEmpty ? .secondary : .red)
                .lineLimit(1)
        }
    }

    private var catalogCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Search Brew Catalog", systemImage: "shippingbox")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
            }

            HStack(spacing: 8) {
                Picker("Kind", selection: $viewModel.discoverKind) {
                    ForEach(BrewPackageKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 250)

                TextField("Find packages to install", text: $viewModel.discoverQuery)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task { await viewModel.searchCatalog() }
                    }

                Button("Add") {
                    Task { await viewModel.searchCatalog() }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isBusy)
            }

            if !viewModel.discoverResults.isEmpty {
                ForEach(viewModel.discoverResults.prefix(6)) { package in
                    HStack {
                        Text(package.name)
                            .font(.system(size: 15, weight: .medium))
                        Spacer()
                        Button(viewModel.isInstalled(package) ? "Reinstall" : "Install") {
                            Task { await viewModel.install(package) }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(viewModel.isBusy)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var countsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            metricsRow(icon: "terminal", title: "You have \(viewModel.installedFormulae.count) Formulae installed", subtitle: "Formulae are packages used through terminal")
            Divider()
            metricsRow(icon: "square.stack", title: "You have \(viewModel.installedCasks.count) Casks installed", subtitle: "Casks are GUI apps managed by Homebrew")
            Divider()
            metricsRow(icon: "point.3.filled.connected.trianglepath.dotted", title: "You have \(viewModel.tapCount) Taps added", subtitle: "Taps provide additional package sources")
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var selectedPackageCard: some View {
        Group {
            if let package = viewModel.selectedPackage {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(package.name)
                                .font(.system(size: 22, weight: .semibold))
                            Text(package.kind.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(package.version.isEmpty ? "unknown version" : package.version)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 10) {
                        Button(viewModel.isInstalled(package) ? "Reinstall" : "Install") {
                            Task { await viewModel.install(package) }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isBusy)

                        Button("Uninstall") {
                            Task { await viewModel.uninstall(package) }
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isBusy || !viewModel.isInstalled(package))
                    }
                }
                .padding(18)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func statusCard<Trailing: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: TypeScale.statusTitle, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: TypeScale.statusSubtitle))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            trailing()
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func metricsRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: TypeScale.metricTitle, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: TypeScale.metricSubtitle))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func iconButton(systemName: String, helpText: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 40, height: 40)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(Circle())
        }
        .help(helpText)
        .buttonStyle(.plain)
        .disabled(viewModel.isBusy)
    }
}

#Preview {
    ContentView()
}
