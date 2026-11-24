import SwiftUI

@main struct MyApp: App {
    private let notebook: Notebook

    init() {
        Fonts.register()
        notebook = Notebook.makeDefault()
    }
    #if !os(macOS)
        @Environment(\.scenePhase) private var scenePhase
    #endif

    var body: some Scene {
        #if os(macOS)
            Window("Everline", id: "main") {
                ContentView(model: notebook.model)
            }
            .windowStyle(.hiddenTitleBar)
        #else
            WindowGroup {
                ContentView(model: notebook.model)
                    .onChange(of: scenePhase) { _, phase in
                        if phase != .active { notebook.lifecycle.leaving() }
                    }
            }
        #endif
    }
}
