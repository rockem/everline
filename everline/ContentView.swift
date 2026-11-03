import SwiftUI

struct ContentView: View {
    @State private var model: NotebookModel

    init(model: NotebookModel = .makeDefault()) {
        _model = State(initialValue: model)
    }

    var body: some View {
        VStack(spacing: 0) {
            WeekStrip(model: model)
            // A fresh editor per day gives each day its own undo history and takes focus on creation.
            NoteEditor(text: Binding(get: { model.text }, set: { model.text = $0 }))
                .id(model.selected)
        }
        .background(Theme.background)
    }
}

#Preview {
    ContentView()
}
