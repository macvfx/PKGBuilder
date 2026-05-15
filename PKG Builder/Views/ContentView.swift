import SwiftUI

struct ContentView: View {
    @ObservedObject var store: PackageBuilderStore

    @State private var showTemplateSheet = false
    @State private var templateName = ""
    @State private var confirmUserFolderInstall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                SourceDropZone(
                    sourcePath: store.sourceDisplayPath,
                    onChooseFile: store.chooseFile,
                    onChooseFolder: store.chooseFolder,
                    onDropURL: store.applyDroppedItem
                )

                installMappingSection
                metadataSection
                outputSection
                signingSection
                templatesSection
                buildSection
                transcriptSection
            }
            .padding(24)
        }
        .frame(minWidth: 980, minHeight: 760)
        .sheet(isPresented: $showTemplateSheet) {
            TemplateEditorSheet(
                name: $templateName,
                onCancel: {
                    showTemplateSheet = false
                    templateName = ""
                },
                onSave: {
                    store.saveTemplate(named: templateName)
                    showTemplateSheet = false
                    templateName = ""
                }
            )
        }
        .alert("Build Error", isPresented: Binding(
            get: { store.buildErrorMessage != nil },
            set: { if !$0 { store.buildErrorMessage = nil } }
        )) {
            Button("OK") { store.buildErrorMessage = nil }
        } message: {
            Text(store.buildErrorMessage ?? "")
        }
        .alert("Install Into User Folder?", isPresented: $confirmUserFolderInstall) {
            Button("Cancel", role: .cancel) { }
            Button("Build Package") {
                Task { await store.buildPackage() }
            }
        } message: {
            Text("The install path points into a user home folder. Source paths are not reused as install paths automatically. Continue only if this destination is intentional.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PKG Builder")
                .font(.system(size: 30, weight: .bold))

            Text("Package a file or folder into an intentional installed target path, with optional signing, reusable templates, and a visible build transcript.")
                .foregroundStyle(.secondary)
        }
    }

    private var installMappingSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                TextField("/Library/Scripts/ScreenSaver", text: $store.installTargetPath)
                    .textFieldStyle(.roundedBorder)

                if store.sourceKind == .file {
                    Picker("File Behavior", selection: $store.fileInstallMode) {
                        ForEach(FileInstallMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(store.fileInstallMode.helpText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if store.sourceKind == .folder {
                    Picker("Folder Behavior", selection: $store.folderInstallMode) {
                        ForEach(FolderInstallMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(store.folderInstallMode.helpText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(exampleInstallPaths)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let warning = store.targetPathWarning {
                    Text(warning)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
        } label: {
            Label("Install Mapping", systemImage: "arrow.down.doc")
                .font(.headline)
        }
    }

    private var metadataSection: some View {
        GroupBox {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 14, verticalSpacing: 12) {
                GridRow {
                    Text("Package Name")
                        .foregroundStyle(.secondary)
                    TextField("ScreenSaver", text: $store.packageName)
                        .textFieldStyle(.roundedBorder)
                }

                GridRow {
                    Text("Version")
                        .foregroundStyle(.secondary)
                    HStack {
                        TextField("1.0.0", text: $store.version)
                            .textFieldStyle(.roundedBorder)
                        Button("Bump Version", action: store.bumpVersion)
                    }
                }

                GridRow {
                    Text("Identifier")
                        .foregroundStyle(.secondary)
                    TextField("com.example.ScreenSaver", text: $store.identifier)
                        .textFieldStyle(.roundedBorder)
                }
            }
        } label: {
            Label("Package Metadata", systemImage: "shippingbox")
                .font(.headline)
        }
    }

    private var outputSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Output Location", selection: $store.outputMode) {
                    ForEach(OutputMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)

                if store.outputMode == .workingDirectory {
                    directoryChooserRow(
                        title: "Working Folder",
                        path: store.workingDirectoryPath,
                        actionTitle: "Choose Working Folder…",
                        action: store.chooseWorkingDirectory
                    )
                }

                if store.outputMode == .customDirectory {
                    directoryChooserRow(
                        title: "Custom Folder",
                        path: store.customOutputDirectoryPath,
                        actionTitle: "Choose Custom Folder…",
                        action: store.chooseCustomOutputDirectory
                    )
                }

                LabeledContent("Output Preview") {
                    Text(store.outputPreviewPath)
                        .font(.callout.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        } label: {
            Label("Output", systemImage: "externaldrive")
                .font(.headline)
        }
    }

    private var signingSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Signing", selection: $store.selectedCertificateName) {
                    Text("Do Not Sign").tag("")
                    ForEach(store.availableCertificates) { certificate in
                        Text(certificate.name).tag(certificate.name)
                    }
                }

                HStack {
                    Button("Refresh Certificates") {
                        Task { await store.refreshCertificates() }
                    }

                    if store.availableCertificates.isEmpty {
                        Text("No installer certificates detected.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } label: {
            Label("Signing", systemImage: "checkmark.shield")
                .font(.headline)
        }
    }

    private var templatesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button("Save as Template…") {
                        templateName = store.packageName.isEmpty ? "New Template" : store.packageName
                        showTemplateSheet = true
                    }

                    Menu("Apply Template") {
                        if store.templates.isEmpty {
                            Text("No templates saved")
                        } else {
                            ForEach(store.templates) { template in
                                Button(template.name) {
                                    store.applyTemplate(template)
                                }
                            }
                        }
                    }

                    Menu("Delete Template") {
                        if store.templates.isEmpty {
                            Text("No templates saved")
                        } else {
                            ForEach(store.templates) { template in
                                Button(template.name, role: .destructive) {
                                    store.deleteTemplate(template)
                                }
                            }
                        }
                    }
                }

                if !store.templates.isEmpty {
                    Text(store.templates.map(\.name).joined(separator: " • "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            Label("Templates", systemImage: "bookmark")
                .font(.headline)
        }
    }

    private var buildSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                if !store.validationMessages.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(store.validationMessages, id: \.self) { message in
                            Text("• \(message)")
                                .foregroundStyle(.orange)
                        }
                    }
                }

                HStack {
                    Button(store.isBuilding ? "Building…" : "Build Package") {
                        if store.targetPathWarning != nil {
                            confirmUserFolderInstall = true
                        } else {
                            Task { await store.buildPackage() }
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(store.isBuilding || store.sourceURL == nil)

                    if store.lastBuiltPackagePath != nil {
                        Button("Reveal Package", action: store.revealLastBuiltPackage)
                    }

                    if store.lastStagingDirectoryPath != nil {
                        Button("Reveal Staging Folder", action: store.revealLastStagingDirectory)
                    }
                }

                Text(store.statusMessage)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("Build", systemImage: "hammer")
                .font(.headline)
        }
    }

    private var transcriptSection: some View {
        GroupBox {
            TextEditor(text: $store.transcript)
                .font(.system(.callout, design: .monospaced))
                .frame(minHeight: 260)
        } label: {
            Label("Transcript", systemImage: "text.alignleft")
                .font(.headline)
        }
    }

    private var exampleInstallPaths: String {
        if store.sourceKind == .file {
            switch store.fileInstallMode {
            case .installIntoDirectory:
                return "Examples: `/Users/Shared/Stickers`, `/Library/Application Support/MyApp/Assets`, `/usr/local/share/icons`"
            case .installAsExactFilePath:
                return "Examples: `/Users/Shared/Stickers/cover.jpg`, `/Library/Scripts/ScreenSaver/cleanup.zsh`, `/usr/local/bin/toolname`"
            }
        }

        return "Examples: `/Users/Shared/MyFolder`, `/Library/Scripts/ScreenSaver`, `/Library/Scripts/ScreenSaver`"
    }

    private func directoryChooserRow(
        title: String,
        path: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(actionTitle, action: action)
            }

            Text(path.isEmpty ? "No folder selected" : path)
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}
