import Foundation

enum PackageSourceKind: String, Codable {
    case file
    case folder

    var displayName: String {
        switch self {
        case .file:
            return "File"
        case .folder:
            return "Folder"
        }
    }
}
