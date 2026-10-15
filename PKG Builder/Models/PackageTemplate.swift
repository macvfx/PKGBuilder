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
    var installedPermissionsMode: InstalledPermissionsMode
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
        installedPermissionsMode: InstalledPermissionsMode,
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
        self.installedPermissionsMode = installedPermissionsMode
        self.outputMode = outputMode
        self.workingDirectoryPath = workingDirectoryPath
        self.customOutputDirectoryPath = customOutputDirectoryPath
        self.signingCertificateName = signingCertificateName
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, packageName, version, identifier, installTargetPath
        case fileInstallMode, folderInstallMode, installedPermissionsMode
        case outputMode, workingDirectoryPath, customOutputDirectoryPath, signingCertificateName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        packageName = try container.decode(String.self, forKey: .packageName)
        version = try container.decode(String.self, forKey: .version)
        identifier = try container.decode(String.self, forKey: .identifier)
        installTargetPath = try container.decode(String.self, forKey: .installTargetPath)
        fileInstallMode = try container.decode(FileInstallMode.self, forKey: .fileInstallMode)
        folderInstallMode = try container.decode(FolderInstallMode.self, forKey: .folderInstallMode)
        installedPermissionsMode = try container.decodeIfPresent(InstalledPermissionsMode.self, forKey: .installedPermissionsMode) ?? .preserveSource
        outputMode = try container.decode(OutputMode.self, forKey: .outputMode)
        workingDirectoryPath = try container.decode(String.self, forKey: .workingDirectoryPath)
        customOutputDirectoryPath = try container.decode(String.self, forKey: .customOutputDirectoryPath)
        signingCertificateName = try container.decode(String.self, forKey: .signingCertificateName)
    }
}
