import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How To Use PKG Builder")
                        .font(.system(size: 24, weight: .semibold))
                    Text("Map a file or folder to its final install destination and build a simple macOS component package.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }

            GroupBox("Quick Start") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose or drop one source file or folder.")
                    Text("Set the install path to where that item should land on the destination Mac.")
                    Text("Pick the correct file or folder behavior and installed permissions, then build the package and review the transcript.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Files") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Use `Into Folder` when the install path is a folder and the selected file should keep its own name.")
                    Text("Use `Exact File Path` when the install path includes the final installed filename, such as `/usr/local/bin/toolname`.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Folders") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Use `Install Folder` when the selected folder itself should be recreated at the destination.")
                    Text("Use `Install Contents` when only the folder's contents should be copied into the destination path.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Installed Permissions") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Keep Original Permissions keeps each source item's current read, write, and execute permissions. Installer may still change its owner to root.")
                    Text("Standard uses 0644 for ordinary files and 0755 for folders and executables. Everyone can read or run them, but only the owner can make changes. This is recommended for most packages.")
                    Text("Everyone Can Edit uses 0666 for ordinary files and 0777 for folders and executables. Every local user can modify the installed payload, so use this only when shared write access is required.")
                    Text("PKG Builder warns before packaging root-owned source items. Root ownership is not automatically an error; the selected permissions determine what other users can do.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Troubleshooting") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The transcript shows the staging path plus the exact `xattr` and `pkgbuild` commands used.")
                    Text("If the package installs to the wrong place, check whether the install path should be a folder path or an exact file path.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Link("code.matx.ca", destination: URL(string: "https://code.matx.ca")!)
                .font(.headline)

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 720, minHeight: 700, alignment: .topLeading)
    }
}
