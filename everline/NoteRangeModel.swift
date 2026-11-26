import Foundation
import Observation

/// Hears about changes as they happen, with the data in the call, so it never has to read the model mid-change.
protocol NoteRangeObserver: AnyObject {
    func textEdited(day: Day, text: String)
    func selectionChanged(to day: Day)
    /// The range changed, by paging or because the selection left it; `first...last` is the new one.
    func rangeChanged(from first: Day, to last: Day)
}

/// Holds today, the selected day, a range of days (today a week) that can move independently of the selection, and
/// the notes of that range plus the selected day. Passive: it announces changes to its observer and never loads, saves
/// or schedules anything itself.
@Observable
final class NoteRangeModel {
    let today: Day
    private(set) var selected: Day
    /// The days whose notes the model holds besides the selected one: today a week. Paging moves it and keeps the
    /// selection; selecting a day outside it moves it to that day's week.
    private(set) var range: ClosedRange<Day>
    let calendar: DayCalendar
    private var notes: [Day: String] = [:]
    /// Attaching an observer reports the current range to it, so it can load what the model starts on.
    @ObservationIgnored weak var observer: NoteRangeObserver? {
        didSet { observer?.rangeChanged(from: range.lowerBound, to: range.upperBound) }
    }

    init(today: Day, calendar: DayCalendar) {
        self.today = today
        selected = today
        range = Self.week(of: today, in: calendar)
        self.calendar = calendar
    }

    private static func week(of day: Day, in calendar: DayCalendar) -> ClosedRange<Day> {
        let days = calendar.week(of: day)
        return (days.first ?? day) ... (days.last ?? day)
    }

    var weekDays: [Day] {
        calendar.week(of: range.lowerBound)
    }

    var text: String {
        get { notes[selected] ?? "" }
        set {
            guard newValue != text else { return }
            notes[selected] = newValue.isEmpty ? nil : newValue
            observer?.textEdited(day: selected, text: newValue)
        }
    }

    /// Whether the day's note has any text. Only days the model holds (the range and the selected day) can have one.
    func hasNote(on day: Day) -> Bool {
        !(notes[day] ?? "").isEmpty
    }

    /// Replaces the notes of the current range, keeping the selected day's own text when it lies outside the range.
    /// Changes no selection and tells no one.
    func loadNotes(_ loaded: [Day: String]) {
        let selectedText = range.contains(selected) ? nil : notes[selected]
        notes = loaded
        notes[selected] = selectedText ?? notes[selected]
    }

    /// Selects a day; the range follows when the day is outside it.
    func select(_ day: Day) {
        guard day != selected else { return }
        selected = day
        observer?.selectionChanged(to: day)
        if !range.contains(day) {
            move(to: Self.week(of: day, in: calendar))
        }
    }

    func nextRange() {
        shiftRange(by: 7)
    }

    private func shiftRange(by days: Int) {
        let first = calendar.adding(days: days, to: range.lowerBound)
        let last = calendar.adding(days: days, to: range.upperBound)
        move(to: first ... last)
    }

    private func move(to newRange: ClosedRange<Day>) {
        range = newRange
        observer?.rangeChanged(from: newRange.lowerBound, to: newRange.upperBound)
    }

    func previousRange() {
        shiftRange(by: -7)
    }
}
