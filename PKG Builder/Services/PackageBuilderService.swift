import Foundation

struct PackageBuildRequest {
    let sourceURL: URL
    let sourceKind: PackageSourceKind
    let installTargetPath: String
    let fileInstallMode: FileInstallMode
    let folderInstallMode: FolderInstallMode
    let installedPermissionsMode: InstalledPermissionsMode
    let packageName: String
    let version: String
    let identifier: String
    let outputURL: URL
    let signingCertificateName: String?
}

enum PackageBuilderError: LocalizedError {
    case invalidInstallPath
    case missingSource
    case missingOutputDirectory

    var errorDescription: String? {
        switch self {
        case .invalidInstallPath:
            return "The install path must be an absolute path."
        case .missingSource:
            return "Choose a source file or folder before building."
        case .missingOutputDirectory:
            return "The output folder could not be created."
        }
    }
}

struct PackageBuilderService {
    func build(request: PackageBuildRequest, log: @escaping @Sendable (String) -> Void) async throws -> PackageBuildResult {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: request.sourceURL.path) else {
            throw PackageBuilderError.missingSource
        }

        guard request.installTargetPath.hasPrefix("/") else {
            throw PackageBuilderError.invalidInstallPath
        }

        let tempRoot = fileManager.temporaryDirectory
            .appendingPathComponent("PKGBuilder-\(UUID().uuidString)", isDirectory: true)
        let payloadRoot = tempRoot.appendingPathComponent("payload", isDirectory: true)

        try fileManager.createDirectory(at: payloadRoot, withIntermediateDirectories: true)

        do {
            log("Staging payload in \(payloadRoot.path)")
            try stagePayload(for: request, into: payloadRoot)
            try applyInstalledPermissions(request.installedPermissionsMode, to: payloadRoot, log: log)

            let outputDirectory = request.outputURL.deletingLastPathComponent()
            do {
                try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
            } catch {
                throw PackageBuilderError.missingOutputDirectory
            }

            if fileManager.fileExists(atPath: request.outputURL.path) {
                try fileManager.removeItem(at: request.outputURL)
            }

            try await runProcess(
                executable: "/usr/bin/xattr",
                arguments: ["-cr", payloadRoot.path],
                log: log
            )

            var arguments = [
                "--root", payloadRoot.path,
                "--identifier", request.identifier,
                "--version", request.version,
                "--ownership", "recommended",
                "--install-location", "/"
            ]

            if let signingCertificateName = request.signingCertificateName, !signingCertificateName.isEmpty {
                arguments += ["--sign", signingCertificateName]
            }

            arguments.append(request.outputURL.path)

            try await runProcess(
                executable: "/usr/bin/pkgbuild",
                arguments: arguments,
                log: log
            )

            try? fileManager.removeItem(at: tempRoot)

            return PackageBuildResult(packageURL: request.outputURL, stagingDirectoryURL: nil)
        } catch {
            log("Build failed. Staged payload kept at \(tempRoot.path)")
            throw BuildFailure(
                result: PackageBuildResult(packageURL: request.outputURL, stagingDirectoryURL: tempRoot),
                underlyingError: error
            )
        }
    }

    private func applyInstalledPermissions(
        _ mode: InstalledPermissionsMode,
        to payloadRoot: URL,
        log: @escaping @Sendable (String) -> Void
    ) throws {
        guard mode != .preserveSource else {
            log("Preserving source POSIX modes. pkgbuild ownership policy: recommended.")
            return
        }

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: payloadRoot,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey],
            options: [],
            errorHandler: { _, _ in true }
        ) else { return }

        var updatedItemCount = 0
        for case let itemURL as URL in enumerator {
            let values = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey])
            if values.isSymbolicLink == true {
                continue
            }

            let permissions: Int
            if values.isDirectory == true {
                permissions = mode == .standard ? 0o755 : 0o777
            } else if values.isRegularFile == true {
                let attributes = try fileManager.attributesOfItem(atPath: itemURL.path)
                let existingPermissions = (attributes[.posixPermissions] as? NSNumber)?.intValue ?? 0
                let isExecutable = existingPermissions & 0o111 != 0
                if mode == .standard {
                    permissions = isExecutable ? 0o755 : 0o644
                } else {
                    permissions = isExecutable ? 0o777 : 0o666
                }
            } else {
                continue
            }

            try fileManager.setAttributes([.posixPermissions: permissions], ofItemAtPath: itemURL.path)
            updatedItemCount += 1
        }

        log("Applied \(mode.displayName) to \(updatedItemCount) staged item\(updatedItemCount == 1 ? "" : "s"). pkgbuild ownership policy: recommended.")
    }

    private func stagePayload(for request: PackageBuildRequest, into payloadRoot: URL) throws {
        let fileManager = FileManager.default
        let relativeTargetPath = request.installTargetPath
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard !relativeTargetPath.isEmpty else {
            throw PackageBuilderError.invalidInstallPath
        }

        switch request.sourceKind {
        case .file:
            switch request.fileInstallMode {
            case .installIntoDirectory:
                let destinationDirectory = payloadRoot.appendingPathComponent(relativeTargetPath, isDirectory: true)
                try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
                let destination = destinationDirectory.appendingPathComponent(request.sourceURL.lastPathComponent)
                try fileManager.copyItem(at: request.sourceURL, to: destination)

            case .installAsExactFilePath:
                let destination = payloadRoot.appendingPathComponent(relativeTargetPath)
                try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                try fileManager.copyItem(at: request.sourceURL, to: destination)
            }

        case .folder:
            switch request.folderInstallMode {
            case .installFolderItself:
                let destination = payloadRoot.appendingPathComponent(relativeTargetPath, isDirectory: true)
                try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                try fileManager.copyItem(at: request.sourceURL, to: destination)

            case .installFolderContents:
                let destinationDirectory = payloadRoot.appendingPathComponent(relativeTargetPath, isDirectory: true)
                try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

                let contents = try fileManager.contentsOfDirectory(at: request.sourceURL, includingPropertiesForKeys: nil)
                for item in contents {
                    let destination = destinationDirectory.appendingPathComponent(item.lastPathComponent)
                    try fileManager.copyItem(at: item, to: destination)
                }
            }
        }
    }

    private func runProcess(
        executable: String,
        arguments: [String],
        log: @escaping @Sendable (String) -> Void
    ) async throws {
        log("$ \(executable) \(arguments.joined(separator: " "))")

        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            let handle = pipe.fileHandleForReading
            handle.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                guard !data.isEmpty else { return }
                if let text = String(data: data, encoding: .utf8) {
                    log(text.trimmingCharacters(in: .newlines))
                }
            }

            process.terminationHandler = { process in
                handle.readabilityHandler = nil
                let trailingData = handle.readDataToEndOfFile()
                if !trailingData.isEmpty, let trailingText = String(data: trailingData, encoding: .utf8) {
                    log(trailingText.trimmingCharacters(in: .newlines))
                }

                if process.terminationStatus == 0 {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "PackageBuilderService",
                        code: Int(process.terminationStatus),
                        userInfo: [
                            NSLocalizedDescriptionKey: "\(URL(fileURLWithPath: executable).lastPathComponent) exited with status \(process.terminationStatus)."
                        ]
                    ))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

struct BuildFailure: LocalizedError {
    let result: PackageBuildResult
    let underlyingError: Error

    var errorDescription: String? {
        underlyingError.localizedDescription
    }
}
