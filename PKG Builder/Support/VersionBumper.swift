import Foundation

enum VersionBumper {
    static func bump(_ version: String) -> String {
        let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "1.0.0" }

        let parts = trimmed.split(separator: ".").map(String.init)
        guard let last = parts.last, let number = Int(last) else {
            return trimmed + ".1"
        }

        var next = parts
        next[next.count - 1] = String(number + 1)
        return next.joined(separator: ".")
    }
}
