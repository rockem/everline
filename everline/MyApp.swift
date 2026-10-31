import SwiftUI

@main struct MyApp: App {
    var body: some Scene {
        #if os(macOS)
        Window("Everline", id: "main") {
            ContentView()
        }
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}
