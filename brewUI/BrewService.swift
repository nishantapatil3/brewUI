import Foundation

struct CommandResult {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

enum BrewServiceError: LocalizedError {
    case brewNotFound
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .brewNotFound:
            return "Homebrew not found. Install Homebrew first."
        case .commandFailed(let message):
            return message
        }
    }
}

final class BrewService {
    private let fileManager = FileManager.default

    func listInstalled(kind: BrewPackageKind) async throws -> [BrewPackage] {
        var args = ["list"]
        if kind == .formula {
            args.append("--formula")
        } else {
            args.append("--cask")
        }
        args.append("--versions")

        let result = try await runBrew(args)
        return parseVersionedPackages(output: result.stdout, kind: kind)
    }

    func search(kind: BrewPackageKind, query: String) async throws -> [BrewPackage] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return []
        }

        var args = ["search"]
        if kind == .formula {
            args.append("--formula")
        } else {
            args.append("--cask")
        }
        args.append(trimmed)

        let result = try await runBrew(args)
        let names = result.stdout
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .filter { !$0.isEmpty }

        let unique = Array(Set(names)).sorted()
        return unique.map { BrewPackage(name: $0, version: "", kind: kind) }
    }

    func install(name: String, kind: BrewPackageKind) async throws -> String {
        var args = ["install"]
        if let flag = kind.installFlag {
            args.append(flag)
        }
        args.append(name)

        let result = try await runBrew(args)
        return combinedOutput(result)
    }

    func reinstall(name: String, kind: BrewPackageKind) async throws -> String {
        var args = ["reinstall"]
        if let flag = kind.installFlag {
            args.append(flag)
        }
        args.append(name)

        let result = try await runBrew(args)
        return combinedOutput(result)
    }

    func uninstall(name: String, kind: BrewPackageKind) async throws -> String {
        var args = ["uninstall"]
        if let flag = kind.installFlag {
            args.append(flag)
        }
        args.append(name)

        let result = try await runBrew(args)
        return combinedOutput(result)
    }

    func ensureBrewAvailable() async throws {
        _ = try await runBrew(["--version"])
    }

    func outdatedCount() async throws -> Int {
        try await outdatedPackageNames().count
    }

    func outdatedPackageNames() async throws -> Set<String> {
        let result = try await runBrew(["outdated", "--quiet"])
        let names = result.stdout
            .split(separator: "\n")
            .map { line in
                line.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? ""
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Set(names)
    }

    func tapCount() async throws -> Int {
        let result = try await runBrew(["tap"])
        return result.stdout
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .count
    }

    func analyticsEnabled() async throws -> Bool {
        let result = try await runBrew(["analytics", "state"])
        let text = result.stdout.lowercased()
        if text.contains("disabled") {
            return false
        }
        if text.contains("enabled") {
            return true
        }
        return true
    }

    func updateMetadata() async throws -> String {
        let result = try await runBrew(["update"])
        return combinedOutput(result)
    }

    func upgradeOutdated() async throws -> String {
        let result = try await runBrew(["upgrade"])
        return combinedOutput(result)
    }

    private func parseVersionedPackages(output: String, kind: BrewPackageKind) -> [BrewPackage] {
        output
            .split(separator: "\n")
            .compactMap { line in
                let columns = line.split(whereSeparator: { $0.isWhitespace })
                guard let first = columns.first else {
                    return nil
                }

                let name = String(first)
                let version = columns.dropFirst().joined(separator: " ")
                return BrewPackage(name: name, version: version, kind: kind)
            }
            .sorted { $0.name < $1.name }
    }

    private func runBrew(_ args: [String]) async throws -> CommandResult {
        let brewPath = try await resolveBrewPath()
        return try await runCommand(executable: brewPath, arguments: args)
    }

    private func resolveBrewPath() async throws -> String {
        let commonPaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        if let path = commonPaths.first(where: { fileManager.isExecutableFile(atPath: $0) }) {
            return path
        }

        let result = try await runCommand(executable: "/bin/zsh", arguments: ["-lc", "command -v brew"])
        let found = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !found.isEmpty else {
            throw BrewServiceError.brewNotFound
        }

        return found
    }

    private func runCommand(executable: String, arguments: [String]) async throws -> CommandResult {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { proc in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                let result = CommandResult(stdout: stdout, stderr: stderr, exitCode: proc.terminationStatus)
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: result)
                } else {
                    let details = self.combinedOutput(result)
                    continuation.resume(throwing: BrewServiceError.commandFailed(details.isEmpty ? "brew command failed" : details))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    nonisolated private func combinedOutput(_ result: CommandResult) -> String {
        [result.stdout, result.stderr]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
