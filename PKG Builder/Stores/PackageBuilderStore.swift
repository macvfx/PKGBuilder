import AppKit
import Combine
import Foundation

@MainActor
final class PackageBuilderStore: ObservableObject {
    @Published var sourceURL: URL?
    @Published var sourceKind: PackageSourceKind?
    @Published var installTargetPath = ""
    @Published var fileInstallMode: FileInstallMode = .installIntoDirectory
    @Published var folderInstallMode: FolderInstallMode = .installFolderItself
    @Published var packageName = ""
    @Published var version = "1.0.0"
    @Published var identifier = ""
    @Published var outputMode: OutputMode = .nextToSource
    @Published var workingDirectoryPath = ""
    @Published var customOutputDirectoryPath = ""
    @Published var selectedCertificateName = ""
    @Published var availableCertificates: [InstallerCertificate] = []
    @Published var templates: [PackageTemplate] = []
    @Published var transcript = ""
    @Published var isBuilding = false
    @Published var statusMessage = "Choose a source file or folder to begin."
    @Published var buildErrorMessage: String?
    @Published var lastBuiltPackagePath: String?
    @Published var lastStagingDirectoryPath: String?

    private let builderService = PackageBuilderService()
    private let certificateService = InstallerCertificateService()
    private let defaults = UserDefaults.standard
    private var cancellables: Set<AnyCancellable> = []

    private enum DefaultsKey {
        static let lastUsedSettings = "PKGBuilder.lastUsedSettings"
        static let savedTemplates = "PKGBuilder.savedTemplates"
    }

    init() {
        loadPersistedSettings()
        bindPersistence()

        Task {
            await refreshCertificates()
        }
    }

    var sourceDisplayPath: String {
        sourceURL?.path ?? "No source selected"
    }

    var targetPathWarning: String? {
        let trimmed = installTargetPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("/Users/"), !trimmed.hasPrefix("/Users/Shared") else { return nil }
        return "Installing into a user home folder is risky. The source location does not determine the install path."
    }

    var outputPreviewPath: String {
        guard let sourceURL else { return "Choose a source to preview the output package path." }

        do {
            return try makeOutputURL(for: sourceURL).path
        } catch {
            return "Choose an output folder to preview the package path."
        }
    }

    var canBuild: Bool {
        validationMessages.isEmpty && !isBuilding
    }

    var validationMessages: [String] {
        var messages: [String] = []
        let fileManager = FileManager.default

        if sourceURL == nil || sourceKind == nil {
            messages.append("Choose a source file or folder.")
        }

        let trimmedTargetPath = installTargetPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTargetPath.isEmpty {
            messages.append("Enter the installed target path.")
        } else if !trimmedTargetPath.hasPrefix("/") {
            messages.append("Install path must be absolute, for example `/Users/Shared/tool.sh`.")
        } else if sourceKind == .file && fileInstallMode == .installAsExactFilePath && trimmedTargetPath.hasSuffix("/") {
            messages.append("A file install path should end with a file name, not a trailing slash.")
        }

        if packageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Enter a package name.")
        }

        if version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Enter a version.")
        }

        let trimmedIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let identifierPattern = #"^[A-Za-z0-9]+(\.[A-Za-z0-9_-]+)+$"#
        if trimmedIdentifier.isEmpty {
            messages.append("Enter a package identifier.")
        } else if trimmedIdentifier.range(of: identifierPattern, options: .regularExpression) == nil {
            messages.append("Identifier should look like `com.example.tool`.")
        }

        switch outputMode {
        case .nextToSource:
            break
        case .workingDirectory:
            if workingDirectoryPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                messages.append("Choose a working folder or change the output mode.")
            } else if !fileManager.fileExists(atPath: workingDirectoryPath) {
                messages.append("Working folder does not exist yet.")
            }
        case .customDirectory:
            if customOutputDirectoryPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                messages.append("Choose a custom output folder.")
            } else if !fileManager.fileExists(atPath: customOutputDirectoryPath) {
                messages.append("Custom output folder does not exist yet.")
            }
        }

        if sourceKind == .folder, let sourceURL {
            if let contents = try? fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil),
               contents.isEmpty {
                messages.append("The selected source folder is empty.")
            }
        }

        return messages
    }

    func chooseFile() {
        chooseSource(canChooseFiles: true, canChooseDirectories: false)
    }

    func chooseFolder() {
        chooseSource(canChooseFiles: false, canChooseDirectories: true)
    }

    func chooseWorkingDirectory() {
        chooseDirectory { [weak self] url in
            self?.workingDirectoryPath = url.path
        }
    }

    func chooseCustomOutputDirectory() {
        chooseDirectory { [weak self] url in
            self?.customOutputDirectoryPath = url.path
        }
    }

    func applyDroppedItem(_ url: URL) {
        setSource(url: url)
    }

    func setSource(url: URL) {
        let path = url.path
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return }

        sourceURL = url
        sourceKind = isDirectory.boolValue ? .folder : .file

        if packageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            packageName = url.deletingPathExtension().lastPathComponent
        }

        statusMessage = "Ready to map \(url.lastPathComponent) into an installed path."
    }

    func bumpVersion() {
        version = VersionBumper.bump(version)
    }

    func saveTemplate(named name: String) {
        let template = PackageTemplate(
            name: name,
            packageName: packageName,
            version: version,
            identifier: identifier,
            installTargetPath: installTargetPath,
            fileInstallMode: fileInstallMode,
            folderInstallMode: folderInstallMode,
            outputMode: outputMode,
            workingDirectoryPath: workingDirectoryPath,
            customOutputDirectoryPath: customOutputDirectoryPath,
            signingCertificateName: selectedCertificateName
        )

        templates.removeAll { $0.name.caseInsensitiveCompare(name) == .orderedSame }
        templates.append(template)
        templates.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        persistTemplates()
    }

    func applyTemplate(_ template: PackageTemplate) {
        packageName = template.packageName
        version = template.version
        identifier = template.identifier
        installTargetPath = template.installTargetPath
        fileInstallMode = template.fileInstallMode
        folderInstallMode = template.folderInstallMode
        outputMode = template.outputMode
        workingDirectoryPath = template.workingDirectoryPath
        customOutputDirectoryPath = template.customOutputDirectoryPath
        selectedCertificateName = template.signingCertificateName
        statusMessage = "Applied template \(template.name)."
    }

    func deleteTemplate(_ template: PackageTemplate) {
        templates.removeAll { $0.id == template.id }
        persistTemplates()
    }

    func refreshCertificates() async {
        do {
            let certificates = try await certificateService.fetchInstallerCertificates()
            availableCertificates = certificates
            if certificates.isEmpty {
                selectedCertificateName = ""
                statusMessage = "No installer certificates detected. Signing is optional."
            } else {
                if selectedCertificateName.isEmpty || !certificates.contains(where: { $0.name == selectedCertificateName }) {
                    selectedCertificateName = certificates[0].name
                }
                statusMessage = "Found \(certificates.count) installer certificate\(certificates.count == 1 ? "" : "s")."
            }
        } catch {
            availableCertificates = []
            selectedCertificateName = ""
            statusMessage = "Certificate lookup failed. You can still build unsigned packages."
        }
    }

    func buildPackage() async {
        transcript = ""
        buildErrorMessage = nil
        lastBuiltPackagePath = nil
        lastStagingDirectoryPath = nil

        let issues = validationMessages
        guard issues.isEmpty else {
            buildErrorMessage = issues.joined(separator: "\n")
            return
        }

        guard let sourceURL, let sourceKind else { return }

        isBuilding = true
        statusMessage = "Building package..."
        appendLog("Preparing build for \(sourceURL.lastPathComponent)")

        do {
            let outputURL = try makeOutputURL(for: sourceURL)
            let request = PackageBuildRequest(
                sourceURL: sourceURL,
                sourceKind: sourceKind,
                installTargetPath: installTargetPath.trimmingCharacters(in: .whitespacesAndNewlines),
                fileInstallMode: fileInstallMode,
                folderInstallMode: folderInstallMode,
                packageName: packageName.trimmingCharacters(in: .whitespacesAndNewlines),
                version: version.trimmingCharacters(in: .whitespacesAndNewlines),
                identifier: identifier.trimmingCharacters(in: .whitespacesAndNewlines),
                outputURL: outputURL,
                signingCertificateName: selectedCertificateName.isEmpty ? nil : selectedCertificateName
            )

            let result = try await builderService.build(request: request) { [weak self] line in
                Task { @MainActor in
                    self?.appendLog(line)
                }
            }

            lastBuiltPackagePath = result.packageURL.path
            statusMessage = "Built \(result.packageURL.lastPathComponent)"
            version = VersionBumper.bump(version)
        } catch let failure as BuildFailure {
            lastStagingDirectoryPath = failure.result.stagingDirectoryURL?.path
            buildErrorMessage = failure.localizedDescription
            statusMessage = "Build failed."
        } catch {
            buildErrorMessage = error.localizedDescription
            statusMessage = "Build failed."
        }

        isBuilding = false
    }

    func revealLastBuiltPackage() {
        guard let lastBuiltPackagePath else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: lastBuiltPackagePath)])
    }

    func revealLastStagingDirectory() {
        guard let lastStagingDirectoryPath else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: lastStagingDirectoryPath)])
    }

    private func chooseSource(canChooseFiles: Bool, canChooseDirectories: Bool) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = canChooseFiles
        panel.canChooseDirectories = canChooseDirectories
        panel.canCreateDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            setSource(url: url)
        }
    }

    private func chooseDirectory(onSelect: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            onSelect(url)
        }
    }

    private func makeOutputURL(for sourceURL: URL) throws -> URL {
        let baseDirectory: URL
        switch outputMode {
        case .nextToSource:
            baseDirectory = sourceURL.deletingLastPathComponent()
        case .workingDirectory:
            baseDirectory = URL(fileURLWithPath: workingDirectoryPath, isDirectory: true)
        case .customDirectory:
            baseDirectory = URL(fileURLWithPath: customOutputDirectoryPath, isDirectory: true)
        }

        let safeName = packageName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
        let safeVersion = version.trimmingCharacters(in: .whitespacesAndNewlines)
        return baseDirectory.appendingPathComponent("\(safeName)-\(safeVersion).pkg")
    }

    private func appendLog(_ message: String) {
        guard !message.isEmpty else { return }
        transcript += message
        if !message.hasSuffix("\n") {
            transcript += "\n"
        }
    }

    private func bindPersistence() {
        Publishers.MergeMany(
            $installTargetPath.map { _ in () }.eraseToAnyPublisher(),
            $fileInstallMode.map { _ in () }.eraseToAnyPublisher(),
            $folderInstallMode.map { _ in () }.eraseToAnyPublisher(),
            $packageName.map { _ in () }.eraseToAnyPublisher(),
            $version.map { _ in () }.eraseToAnyPublisher(),
            $identifier.map { _ in () }.eraseToAnyPublisher(),
            $outputMode.map { _ in () }.eraseToAnyPublisher(),
            $workingDirectoryPath.map { _ in () }.eraseToAnyPublisher(),
            $customOutputDirectoryPath.map { _ in () }.eraseToAnyPublisher(),
            $selectedCertificateName.map { _ in () }.eraseToAnyPublisher()
        )
        .dropFirst()
        .sink { [weak self] in
            self?.persistLastUsedSettings()
        }
        .store(in: &cancellables)
    }

    private func loadPersistedSettings() {
        if let data = defaults.data(forKey: DefaultsKey.lastUsedSettings),
           let settings = try? JSONDecoder().decode(PersistedSettings.self, from: data) {
            installTargetPath = settings.installTargetPath
            fileInstallMode = settings.fileInstallMode
            folderInstallMode = settings.folderInstallMode
            packageName = settings.packageName
            version = settings.version
            identifier = settings.identifier
            outputMode = settings.outputMode
            workingDirectoryPath = settings.workingDirectoryPath
            customOutputDirectoryPath = settings.customOutputDirectoryPath
            selectedCertificateName = settings.selectedCertificateName
        }

        if let data = defaults.data(forKey: DefaultsKey.savedTemplates),
           let savedTemplates = try? JSONDecoder().decode([PackageTemplate].self, from: data) {
            templates = savedTemplates
        }
    }

    private func persistLastUsedSettings() {
        let settings = PersistedSettings(
            installTargetPath: installTargetPath,
            fileInstallMode: fileInstallMode,
            folderInstallMode: folderInstallMode,
            packageName: packageName,
            version: version,
            identifier: identifier,
            outputMode: outputMode,
            workingDirectoryPath: workingDirectoryPath,
            customOutputDirectoryPath: customOutputDirectoryPath,
            selectedCertificateName: selectedCertificateName
        )

        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: DefaultsKey.lastUsedSettings)
        }
    }

    private func persistTemplates() {
        if let data = try? JSONEncoder().encode(templates) {
            defaults.set(data, forKey: DefaultsKey.savedTemplates)
        }
    }
}

private struct PersistedSettings: Codable {
    var installTargetPath: String
    var fileInstallMode: FileInstallMode
    var folderInstallMode: FolderInstallMode
    var packageName: String
    var version: String
    var identifier: String
    var outputMode: OutputMode
    var workingDirectoryPath: String
    var customOutputDirectoryPath: String
    var selectedCertificateName: String
}
