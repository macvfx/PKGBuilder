import Foundation

enum FileInstallMode: String, CaseIterable, Codable, Identifiable {
    case installIntoDirectory
    case installAsExactFilePath

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .installIntoDirectory:
            return "Into Folder"
        case .installAsExactFilePath:
            return "Exact File Path"
        }
    }

    var helpText: String {
        switch self {
        case .installIntoDirectory:
            return "The selected file keeps its own name and is placed inside the target folder."
        case .installAsExactFilePath:
            return "The target path is treated as the final installed file path and name."
        }
    }
}
