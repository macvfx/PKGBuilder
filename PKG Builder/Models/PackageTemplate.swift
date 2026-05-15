import Foundation

struct PackageTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var packageName: String
    var version: String
    var identifier: String
    var installTargetPath: String
    var fileInstallMode: FileInstallMode
    var folderInstallMode: FolderInstallMode
    var outputMode: OutputMode
    var workingDirectoryPath: String
    var customOutputDirectoryPath: String
    var signingCertificateName: String

    init(
        id: UUID = UUID(),
        name: String,
        packageName: String,
        version: String,
        identifier: String,
        installTargetPath: String,
        fileInstallMode: FileInstallMode,
        folderInstallMode: FolderInstallMode,
        outputMode: OutputMode,
        workingDirectoryPath: String,
        customOutputDirectoryPath: String,
        signingCertificateName: String
    ) {
        self.id = id
        self.name = name
        self.packageName = packageName
        self.version = version
        self.identifier = identifier
        self.installTargetPath = installTargetPath
        self.fileInstallMode = fileInstallMode
        self.folderInstallMode = folderInstallMode
        self.outputMode = outputMode
        self.workingDirectoryPath = workingDirectoryPath
        self.customOutputDirectoryPath = customOutputDirectoryPath
        self.signingCertificateName = signingCertificateName
    }
}
