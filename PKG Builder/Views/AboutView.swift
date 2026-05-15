import AppKit
import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var versionString: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "Version \(shortVersion) (\(buildVersion))"
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            VStack(spacing: 6) {
                Text("PKG Builder")
                    .font(.system(size: 24, weight: .semibold))
                Text("Build simple macOS component packages from files and folders.")
                    .foregroundStyle(.secondary)
                Text(versionString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Link("code.matx.ca", destination: URL(string: "https://code.matx.ca")!)

            Button("Done") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(28)
        .frame(minWidth: 380, minHeight: 320)
    }
}
