@testable import everline
import XCTest

final class NotePersistorTests: XCTestCase {
    private var store: FakeNoteStore!
    private var model: NoteRangeModel!
    private var persistor: NotePersistor!

    override func setUp() {
        store = store ?? FakeNoteStore()
        model = NoteRangeModel(today: day("2026-10-28"), calendar: DayCalendar(makeCalendar()))
        persistor = NotePersistor(store: store, model: model)
        model.observer = persistor
        store.calls = []
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func day(_ iso: String) -> Day {
        Day(iso: iso)!
    }

    func testSavesTheEditedDayWhenAnotherIsSelected() {
        model.text = "monday"
        model.select(day("2026-10-29"))

        XCTAssertEqual(store.calls, [.save(day("2026-10-28"), "monday")])
    }

    func testLaterEditReplacesTheEarlierOne() {
        model.text = "a"
        model.text = "ab"

        model.select(day("2026-10-29"))

        XCTAssertEqual(store.saves, [.save(day("2026-10-28"), "ab")])
    }

    func testUntouchedDaysAreNeverSaved() {
        model.select(day("2026-10-29"))
        model.select(day("2026-10-30"))
        model.nextRange()

        XCTAssertEqual(store.saves, [])
    }

    func testASavedEditIsNotSavedAgain() {
        model.text = "a"

        model.select(day("2026-10-29"))
        model.select(day("2026-10-30"))
        model.nextRange()

        XCTAssertEqual(store.saves, [.save(day("2026-10-28"), "a")])
    }

    func testRangeChangeSavesThenLoadsBeforeReturning() {
        store.notes = [day("2026-11-04"): "next week"]
        model.text = "mine"

        model.nextRange()

        XCTAssertEqual(store.calls, [
            .save(day("2026-10-28"), "mine"),
            .load(day("2026-11-02"), day("2026-11-08"))
        ])
        XCTAssertEqual(model.text, "mine")
        model.select(day("2026-11-04"))
        XCTAssertEqual(model.text, "next week")
    }

    func testReturningToARangeShowsWhatWasSaved() {
        model.text = "mine"

        model.nextRange()
        model.previousRange()

        XCTAssertEqual(model.text, "mine")
    }
}
