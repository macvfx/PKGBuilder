import AppKit
import SwiftUI

@main
struct PKGBuilderApp: App {
    @StateObject private var store = PackageBuilderStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
        .defaultSize(width: 1120, height: 860)
        .commands {
            PKGBuilderCommands()
        }

        Window("Help", id: "help") {
            HelpView()
        }

        Window("About PKG Builder", id: "about") {
            AboutView()
        }
    }
}

private struct PKGBuilderCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About PKG Builder") {
                openWindow(id: "about")
            }
        }

        CommandGroup(replacing: .help) {
            Button("PKG Builder Help") {
                openWindow(id: "help")
            }
            .keyboardShortcut("/", modifiers: [.command, .shift])

            Divider()

            Link("code.matx.ca", destination: URL(string: "https://code.matx.ca")!)
        }
    }
}
