import SwiftUI
import ViewInspector
import XCTest
@testable import everline

@MainActor
final class WeekStripTests: XCTestCase {
    private var model: NotebookModel!

    override func setUp() {
        model = makeModel(firstWeekday: 2)
    }

    private func makeModel(firstWeekday: Int) -> NotebookModel {
        let calendar = calendar(firstWeekday: firstWeekday)
        return NotebookModel(today: Day(2026, 10, 28), calendar: DayCalendar(calendar))
    }

    private func calendar(firstWeekday: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = firstWeekday
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    func testShowsSevenDaysStartingOnMonday() throws {
        XCTAssertEqual(try dayIds(),
                       ["day-2026-10-26", "day-2026-10-27", "day-2026-10-28", "day-2026-10-29",
                        "day-2026-10-30", "day-2026-10-31", "day-2026-11-01"])
    }

    private func dayIds() throws -> [String] {
        try WeekStrip(model: model).inspect().findAll(ViewType.Button.self)
            .map { try $0.accessibilityIdentifier() }
            .filter { $0.hasPrefix("day-") }
    }

    func testShowsSevenDaysStartingOnSunday() throws {
        model = makeModel(firstWeekday: 1)

        let ids = try dayIds()

        XCTAssertEqual(ids.first, "day-2026-10-25")
        XCTAssertEqual(ids.last, "day-2026-10-31")
    }

    func testSelectedDayIsMarkedSelected() throws {
        let selected = try dayIds().filter { id in
            try button(id).accessibilityTraits().contains(.isSelected)
        }

        XCTAssertEqual(selected, ["day-2026-10-28"])
    }

    private func button(_ identifier: String) throws -> InspectableView<ViewType.Button> {
        try WeekStrip(model: model).inspect().find(viewWithAccessibilityIdentifier: identifier).button()
    }

    func testTodayIsLabeledToday() throws {
        XCTAssertTrue(try button("day-2026-10-28").accessibilityLabel().string().contains("today"))
        XCTAssertFalse(try button("day-2026-10-29").accessibilityLabel().string().contains("today"))
    }

    func testPressingADaySelectsIt() throws {
        try button("day-2026-10-29").tap()

        XCTAssertEqual(model.selected.id, "2026-10-29")
    }

    func testNextAndPreviousButtonsMoveByWeek() throws {
        try button("next-week").tap()

        XCTAssertEqual(model.selected.id, "2026-11-04")
        XCTAssertEqual(try dayIds().first, "day-2026-11-02")
        XCTAssertEqual(try dayIds().last, "day-2026-11-08")

        try button("previous-week").tap()

        XCTAssertEqual(model.selected.id, "2026-10-28")
    }
}
