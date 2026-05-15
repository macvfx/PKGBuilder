import Foundation

struct InstallerCertificateService {
    func fetchInstallerCertificates() async throws -> [InstallerCertificate] {
        let output = try await runCommand(
            executable: "/usr/bin/security",
            arguments: ["find-identity", "-v"]
        )

        let installerNameMarkers = [
            "Developer ID Installer",
            "3rd Party Mac Developer Installer"
        ]

        let certificates = output
            .split(separator: "\n")
            .compactMap { line -> InstallerCertificate? in
                guard let quoteStart = line.firstIndex(of: "\""),
                      let quoteEnd = line.lastIndex(of: "\""),
                      quoteEnd > quoteStart else {
                    return nil
                }

                let name = String(line[line.index(after: quoteStart)..<quoteEnd])
                guard installerNameMarkers.contains(where: { name.localizedCaseInsensitiveContains($0) }) else {
                    return nil
                }
                let prefix = line[..<quoteStart]
                let tokens = prefix.split(whereSeparator: \.isWhitespace)
                guard tokens.count >= 2 else { return nil }
                let hash = String(tokens[1])
                return InstallerCertificate(hash: hash, name: name)
            }
            .sorted {
                let lhsPreferred = $0.name.contains("Developer ID Installer")
                let rhsPreferred = $1.name.contains("Developer ID Installer")
                if lhsPreferred != rhsPreferred {
                    return lhsPreferred && !rhsPreferred
                }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

        return certificates
    }

    private func runCommand(executable: String, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            process.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "InstallerCertificateService",
                        code: Int(process.terminationStatus),
                        userInfo: [NSLocalizedDescriptionKey: output.isEmpty ? "Certificate lookup failed." : output]
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
