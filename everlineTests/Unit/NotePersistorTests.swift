@testable import everline
import XCTest

final class NotePersistorTests: XCTestCase {
    private var store: FakeNoteStore!
    private var model: NoteRangeModel!
    private var persistor: NotePersistor!
    private var scheduler: ManualScheduler!
    private var lifecycle: AppLifecycle!

    override func setUp() {
        store = store ?? FakeNoteStore()
        scheduler = ManualScheduler()
        lifecycle = AppLifecycle(center: NotificationCenter())
        model = NoteRangeModel(today: day("2026-10-28"), calendar: DayCalendar(makeCalendar()))
        persistor = NotePersistor(
            store: store,
            model: model,
            scheduler: scheduler,
            lifecycle: lifecycle,
            timing: AutosaveTiming(idle: 2, deadline: 5)
        )
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

    func testSavesAfterTypingPauses() {
        model.text = "a"
        model.text = "ab"

        scheduler.advance(by: 2)

        XCTAssertEqual(store.saves, [.save(day("2026-10-28"), "ab")])
    }

    func testSavesWhileTypingContinuesAtTheDeadline() {
        for letter in ["a", "b", "c", "d", "e"] {
            model.text += letter
            scheduler.advance(by: 1)
        }

        XCTAssertEqual(store.saves, [.save(day("2026-10-28"), "abcde")])
    }

    func testLeavingTheAppSavesTheEdit() {
        model.text = "a"

        lifecycle.leaving()

        XCTAssertEqual(store.saves, [.save(day("2026-10-28"), "a")])
    }

    func testLeavingTheAppCancelsTheWaitingSave() {
        model.text = "a"
        lifecycle.leaving()

        scheduler.advance(by: 60)

        XCTAssertEqual(store.saves, [.save(day("2026-10-28"), "a")])
    }

    func testAFailedSaveIsRetried() {
        model.text = "a"
        store.failuresLeft = 1
        model.select(day("2026-10-29"))

        scheduler.advance(by: 2)

        XCTAssertEqual(store.saves, [.save(day("2026-10-28"), "a"), .save(day("2026-10-28"), "a")])
        XCTAssertEqual(store.notes[day("2026-10-28")], "a")
    }

    func testAFailedEditSurvivesPagingAwayAndBack() {
        model.text = "mine"
        store.failsSaves = true

        model.nextRange()
        model.previousRange()

        XCTAssertEqual(model.text, "mine")
        store.failsSaves = false
        scheduler.advance(by: 2)
        XCTAssertEqual(store.notes[day("2026-10-28")], "mine")
    }

    func testAFailedEditSurvivesAnEditOnAnotherDay() {
        model.text = "a"
        store.failsSaves = true
        model.select(day("2026-10-29"))
        model.text = "b"
        store.failsSaves = false

        model.select(day("2026-10-30"))

        XCTAssertEqual(store.notes, [day("2026-10-28"): "a", day("2026-10-29"): "b"])
    }

    func testSavesNothingWithoutAnEdit() {
        scheduler.advance(by: 60)

        XCTAssertEqual(store.calls, [])
    }

    func testSwitchingDayCancelsTheWaitingSave() {
        model.text = "a"
        model.select(day("2026-10-29"))

        scheduler.advance(by: 60)

        XCTAssertEqual(store.saves, [.save(day("2026-10-28"), "a")])
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
