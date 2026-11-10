import Foundation
import Observation

/// Holds today, the selected day and the in-memory text of every day written so far.
@Observable
final class NotebookModel {
    let today: Day
    private(set) var selected: Day
    let calendar: DayCalendar
    private var notes: [Day: String] = [:]

    init(today: Day, calendar: DayCalendar) {
        self.today = today
        self.selected = today
        self.calendar = calendar
    }

    var weekDays: [Day] {
        calendar.week(of: selected)
    }

    var text: String {
        get { notes[selected] ?? "" }
        set { notes[selected] = newValue.isEmpty ? nil : newValue }
    }

    func select(_ day: Day) {
        selected = day
    }

    func showNextWeek() {
        selected = calendar.adding(days: 7, to: selected)
    }

    func showPreviousWeek() {
        selected = calendar.adding(days: -7, to: selected)
    }
}

extension NotebookModel {
    /// The real app model. `EVERLINE_TODAY=YYYY-MM-DD` overrides today so UI tests are deterministic.
    static func makeDefault() -> NotebookModel {
        let calendar = DayCalendar(.current)
        let override = ProcessInfo.processInfo.environment["EVERLINE_TODAY"]
        let today = override.flatMap { Day(iso: $0) } ?? calendar.day(of: Date())
        return NotebookModel(today: today, calendar: calendar)
    }
}
