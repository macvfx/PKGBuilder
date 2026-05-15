import SwiftUI
import UniformTypeIdentifiers

struct SourceDropZone: View {
    let sourcePath: String
    let onChooseFile: () -> Void
    let onChooseFolder: () -> Void
    let onDropURL: (URL) -> Void

    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Source")
                .font(.headline)

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isTargeted ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isTargeted ? Color.accentColor : Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    )

                VStack(spacing: 10) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)

                    Text("Drop a file or folder here")
                        .font(.title3.weight(.semibold))

                    Text("The dropped item is only the source. You choose the installed target path separately.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)

                    HStack {
                        Button("Choose File…", action: onChooseFile)
                        Button("Choose Folder…", action: onChooseFolder)
                    }
                }
                .padding(28)
            }
            .frame(minHeight: 220)
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }

            Text(sourcePath)
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .foregroundStyle(.secondary)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }

            DispatchQueue.main.async {
                onDropURL(url)
            }
        }

        return true
    }
}
