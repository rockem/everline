import SwiftUI

@main struct MyApp: App {
    private let notebook = Notebook.makeDefault()

    var body: some Scene {
        #if os(macOS)
        Window("Everline", id: "main") {
            ContentView(model: notebook.model)
        }
        #else
        WindowGroup {
            ContentView(model: notebook.model)
        }
        #endif
    }
}
