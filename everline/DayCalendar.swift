import Foundation

/// Date arithmetic for `Day`s through one `Calendar`, which also decides the first day of the week.
struct DayCalendar {
    private let calendar: Calendar

    init(_ calendar: Calendar) {
        self.calendar = calendar
    }

    /// The seven days of the week containing `day`, starting at the calendar's first weekday.
    func week(of day: Day) -> [Day] {
        let weekday = calendar.component(.weekday, from: date(of: day))
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        let start = adding(days: -offset, to: day)
        return (0 ..< 7).map { adding(days: $0, to: start) }
    }

    /// The start of `day` in this calendar's time zone.
    func date(of day: Day) -> Date {
        calendar.date(from: DateComponents(year: day.year, month: day.month, day: day.day))
            ?? Date(timeIntervalSince1970: 0)
    }

    func adding(days: Int, to day: Day) -> Day {
        let start = date(of: day)
        return self.day(of: calendar.date(byAdding: .day, value: days, to: start) ?? start)
    }

    func day(of date: Date) -> Day {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return Day(parts.year ?? 1, parts.month ?? 1, parts.day ?? 1)
    }

    /// Parses `YYYY-MM-DD`; nil when malformed or not a real date.
    func day(iso: String) -> Day? {
        let parts = iso.split(separator: "-", omittingEmptySubsequences: false).map { Int($0) }
        guard parts.count == 3, let year = parts[0], let month = parts[1], let day = parts[2] else { return nil }
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components),
              calendar.dateComponents([.year, .month, .day], from: date) == components else { return nil }
        return Day(year, month, day)
    }
}
