import SwiftUI

struct ContentView: View {
    @State private var model: NoteRangeModel

    init(model: NoteRangeModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        VStack(spacing: 0) {
            WeekStrip(model: model)
                .padding(.top, Self.windowButtonsBand)
            VStack(alignment: .leading, spacing: 32) {
                PageHeader(day: model.selected, calendar: model.calendar)
                // A fresh editor per day gives each day its own undo history and takes focus on creation.
                NoteEditor(text: Binding(get: { model.text }, set: { model.text = $0 }))
                    .id(model.selected)
            }
            .frame(maxWidth: 680)
            .padding(.horizontal, 24)
            .padding(.top, 56)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        #if os(macOS)
            // The title bar is hidden (see `MyApp`), so the content reaches the top edge; the band above the strip
            // keeps the window buttons clear of it.
            .ignoresSafeArea(.container, edges: .top)
        #endif
    }

    /// The height of the title bar the window no longer has: room for the traffic-light buttons on macOS.
    private static let windowButtonsBand: CGFloat = {
        #if os(macOS)
            28
        #else
            0
        #endif
    }()
}

#Preview {
    ContentView(model: NoteRangeModel(today: Day(2026, 10, 28), calendar: DayCalendar(.current)))
}
