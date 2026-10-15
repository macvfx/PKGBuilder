import Foundation

enum InstalledPermissionsMode: String, CaseIterable, Codable, Identifiable {
    case preserveSource
    case standard
    case writableByAllUsers

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .preserveSource:
            return "Keep Original Permissions"
        case .standard:
            return "Standard — 0644 Files, 0755 Folders/Executables"
        case .writableByAllUsers:
            return "Everyone Can Edit — 0666 Files, 0777 Folders/Executables"
        }
    }

    var helpText: String {
        switch self {
        case .preserveSource:
            return "Each installed file and folder keeps the same read, write, and execute permissions it has now. For example, a source file with 0600 remains accessible only to its owner. Installer may still change the owner to root."
        case .standard:
            return "Recommended for most packages. Folders and executable files become 0755: everyone can open or run them, but only the owner can change them. Other files become 0644: everyone can read them, but only the owner can edit them."
        case .writableByAllUsers:
            return "Every local user can modify the installed payload. Folders and executable files become 0777; other files become 0666. This can solve shared-file write access, but it is less secure and should be used only when required."
        }
    }
}
