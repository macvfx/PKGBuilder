import Foundation

enum FolderInstallMode: String, CaseIterable, Codable, Identifiable {
    case installFolderItself
    case installFolderContents

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .installFolderItself:
            return "Install Folder"
        case .installFolderContents:
            return "Install Contents"
        }
    }

    var helpText: String {
        switch self {
        case .installFolderItself:
            return "The dropped folder becomes part of the installed path."
        case .installFolderContents:
            return "Only the folder's contents are installed into the target directory."
        }
    }
}
