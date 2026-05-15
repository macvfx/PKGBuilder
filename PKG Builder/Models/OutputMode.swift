import Foundation

enum OutputMode: String, CaseIterable, Codable, Identifiable {
    case nextToSource
    case workingDirectory
    case customDirectory

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nextToSource:
            return "Beside Source"
        case .workingDirectory:
            return "Working Folder"
        case .customDirectory:
            return "Custom Folder"
        }
    }
}
