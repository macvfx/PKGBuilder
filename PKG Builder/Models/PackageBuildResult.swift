import Foundation

struct PackageBuildResult {
    let packageURL: URL
    let stagingDirectoryURL: URL?
}

struct InstallerCertificate: Identifiable, Equatable {
    let id: String
    let hash: String
    let name: String

    init(hash: String, name: String) {
        self.id = hash
        self.hash = hash
        self.name = name
    }
}
