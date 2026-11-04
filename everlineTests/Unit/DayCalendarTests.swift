import XCTest
@testable import everline

final class DayCalendarTests: XCTestCase {
    func testWeekStartsOnMondayWhenCalendarSaysSo() {
        let week = dayCalendar(firstWeekday: 2).week(of: Day(2026, 10, 28))

        XCTAssertEqual(ids(week), ["2026-10-26", "2026-10-27", "2026-10-28", "2026-10-29",
                                   "2026-10-30", "2026-10-31", "2026-11-01"])
    }

    private func dayCalendar(firstWeekday: Int, timeZone: String = "UTC") -> DayCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = firstWeekday
        calendar.timeZone = TimeZone(identifier: timeZone)!
        return DayCalendar(calendar)
    }

    private func ids(_ days: [Day]) -> [String] {
        days.map(\.id)
    }

    func testWeekStartsOnSundayWhenCalendarSaysSo() {
        let week = dayCalendar(firstWeekday: 1).week(of: Day(2026, 10, 28))

        XCTAssertEqual(ids(week).first, "2026-10-25")
        XCTAssertEqual(ids(week).last, "2026-10-31")
    }

    func testWeekCrossingYearBoundary() {
        let week = dayCalendar(firstWeekday: 2).week(of: Day(2026, 12, 31))

        XCTAssertEqual(ids(week), ["2026-12-28", "2026-12-29", "2026-12-30", "2026-12-31",
                                   "2027-01-01", "2027-01-02", "2027-01-03"])
    }

    func testWeekAcrossDaylightSavingChange() {
        let week = dayCalendar(firstWeekday: 2, timeZone: "America/New_York").week(of: Day(2026, 11, 1))

        XCTAssertEqual(Set(ids(week)).count, 7)
        XCTAssertEqual(ids(week).first, "2026-10-26")
        XCTAssertEqual(ids(week).last, "2026-11-01")
    }

    func testAddingDaysCrossesMonths() {
        let calendar = dayCalendar(firstWeekday: 2)

        XCTAssertEqual(calendar.adding(days: 1, to: Day(2026, 10, 31)), Day(2026, 11, 1))
        XCTAssertEqual(calendar.adding(days: -7, to: Day(2026, 11, 1)), Day(2026, 10, 25))
    }

    func testIsoStringRoundTrip() {
        let calendar = dayCalendar(firstWeekday: 2)

        XCTAssertEqual(calendar.day(iso: "2026-10-28")?.id, "2026-10-28")
        XCTAssertNil(calendar.day(iso: "nope"))
        XCTAssertNil(calendar.day(iso: "2026-02-30"))
    }

    func testDateIsStartOfThatDay() {
        let calendar = dayCalendar(firstWeekday: 2, timeZone: "America/New_York")
        let today = Day(2026, 10, 28)

        XCTAssertEqual(calendar.day(of: calendar.date(of: today)), today)
    }
}
