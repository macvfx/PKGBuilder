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
    }
}
