import Foundation

/// A calendar day, independent of time zone and time of day. Pure data: use `DayCalendar` for date arithmetic.
struct Day: Hashable, Comparable, Identifiable {
    let year: Int
    let month: Int
    let day: Int

    init(_ year: Int, _ month: Int, _ day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    var id: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func < (lhs: Day, rhs: Day) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}
