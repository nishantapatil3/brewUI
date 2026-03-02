import Foundation

enum BrewPackageKind: String, CaseIterable, Identifiable {
    case formula
    case cask

    var id: String { rawValue }

    var title: String {
        switch self {
        case .formula:
            return "Formulae"
        case .cask:
            return "Casks"
        }
    }

    var installFlag: String? {
        switch self {
        case .formula:
            return nil
        case .cask:
            return "--cask"
        }
    }
}

struct BrewPackage: Identifiable, Hashable {
    let name: String
    let version: String
    let kind: BrewPackageKind

    var id: String { "\(kind.rawValue):\(name)" }
}
