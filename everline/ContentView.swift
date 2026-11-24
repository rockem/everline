import SwiftUI

struct ContentView: View {
    @State private var model: NoteRangeModel

    init(model: NoteRangeModel) {
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
    ContentView(model: NoteRangeModel(today: Day(2026, 10, 28), calendar: DayCalendar(.current)))
}
