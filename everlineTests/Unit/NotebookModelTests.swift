@testable import everline
import XCTest

final class NotebookModelTests: XCTestCase {
    func testOpensOnToday() {
        let model = makeModel()

        XCTAssertEqual(model.selected, day("2026-10-28"))
        XCTAssertEqual(model.text, "")
    }

    private func makeModel() -> NotebookModel {
        NotebookModel(today: day("2026-10-28"), calendar: DayCalendar(calendar))
    }

    private func day(_ iso: String) -> Day {
        Day(iso: iso)!
    }

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    func testWeekDaysContainSelectedDay() {
        let model = makeModel()

        XCTAssertEqual(model.weekDays.count, 7)
        XCTAssertTrue(model.weekDays.contains(model.selected))
        XCTAssertEqual(model.weekDays.first, day("2026-10-26"))
    }

    func testEachDayKeepsItsOwnText() {
        let model = makeModel()

        model.text = "a"
        model.select(day("2026-10-29"))
        model.text = "b"
        model.select(day("2026-10-28"))
        XCTAssertEqual(model.text, "a")
        model.select(day("2026-10-29"))
        XCTAssertEqual(model.text, "b")
    }

    func testNextWeekMovesSelectionBySevenDays() {
        let model = makeModel()

        model.showNextWeek()

        XCTAssertEqual(model.selected, day("2026-11-04"))
        XCTAssertEqual(model.weekDays.first, day("2026-11-02"))
    }

    func testPreviousWeekThenNextWeekReturnsToSameDayWithItsText() {
        let model = makeModel()
        model.text = "x"

        model.showPreviousWeek()
        model.showNextWeek()

        XCTAssertEqual(model.selected, day("2026-10-28"))
        XCTAssertEqual(model.text, "x")
    }

    func testTextOfAnotherWeekIsNotLost() {
        let model = makeModel()
        model.text = "x"

        model.showNextWeek()
        model.text = "y"
        model.showPreviousWeek()

        XCTAssertEqual(model.text, "x")
    }
}
