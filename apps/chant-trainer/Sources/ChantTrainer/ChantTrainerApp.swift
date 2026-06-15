import SwiftUI

@main
struct ChantTrainerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 750)
        .windowResizability(.contentMinSize)
        #endif
    }
}
