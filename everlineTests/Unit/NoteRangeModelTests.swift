@testable import everline
import XCTest

final class NoteRangeModelTests: XCTestCase {
    /// The model holds its observer weakly, so the test keeps it alive.
    fileprivate var observerKeeper: RecordingObserver?

    func testOpensOnToday() {
        let model = makeModel()

        XCTAssertEqual(model.selected, day("2026-10-28"))
        XCTAssertEqual(model.text, "")
    }

    fileprivate func makeModel() -> NoteRangeModel {
        NoteRangeModel(today: day("2026-10-28"), calendar: DayCalendar(calendar))
    }

    fileprivate func day(_ iso: String) -> Day {
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

    func testNextRangeMovesTheRangeButNotTheSelection() {
        let model = makeModel()

        model.nextRange()

        XCTAssertEqual(model.selected, day("2026-10-28"))
        XCTAssertEqual(model.weekDays.first, day("2026-11-02"))
        XCTAssertEqual(model.range, day("2026-11-02") ... day("2026-11-08"))
    }

    func testPreviousWeekThenNextWeekReturnsToSameDayWithItsText() {
        let model = makeModel()
        model.text = "x"

        model.previousRange()
        model.nextRange()

        XCTAssertEqual(model.selected, day("2026-10-28"))
        XCTAssertEqual(model.text, "x")
    }

    func testTextOfAnotherWeekIsNotLost() {
        let model = makeModel()
        model.text = "x"

        model.select(day("2026-11-04"))
        model.text = "y"
        model.select(day("2026-10-28"))

        XCTAssertEqual(model.text, "x")
    }
}

// MARK: - Observer and loading

extension NoteRangeModelTests {
    func testAttachingAnObserverReportsTheCurrentRange() {
        let model = makeModel()
        let observer = RecordingObserver()

        model.observer = observer

        XCTAssertEqual(observer.events, [.range(day("2026-10-26"), day("2026-11-01"))])
    }

    func testEditingTextTellsObserverTheDayAndText() {
        let (model, observer) = makeObservedModel()

        model.text = "hello"

        XCTAssertEqual(observer.events, [.edited(day("2026-10-28"), "hello")])
    }

    func testSettingTheSameTextTellsNoOne() {
        let (model, observer) = makeObservedModel()
        model.text = "hello"
        observer.events = []

        model.text = "hello"

        XCTAssertEqual(observer.events, [])
    }

    func testSelectingAnotherDayInTheSameRangeReportsOnlyTheSelection() {
        let (model, observer) = makeObservedModel()

        model.select(day("2026-10-29"))

        XCTAssertEqual(observer.events, [.selected(day("2026-10-29"))])
    }

    func testSelectingTheSameDayTellsNoOne() {
        let (model, observer) = makeObservedModel()

        model.select(day("2026-10-28"))

        XCTAssertEqual(observer.events, [])
    }

    func testNextRangeReportsOnlyTheNewRange() {
        let (model, observer) = makeObservedModel()

        model.nextRange()

        XCTAssertEqual(observer.events, [.range(day("2026-11-02"), day("2026-11-08"))])
    }

    func testSelectingADayInAnotherRangeReportsTheNewRange() {
        let (model, observer) = makeObservedModel()

        model.select(day("2026-10-25"))

        XCTAssertEqual(observer.events, [.selected(day("2026-10-25")), .range(day("2026-10-19"), day("2026-10-25"))])
    }

    func testLoadNotesReplacesTheNotesOfTheRange() {
        let model = makeModel()
        model.text = "old"

        model.loadNotes([day("2026-10-29"): "loaded"])

        XCTAssertEqual(model.text, "")
        model.select(day("2026-10-29"))
        XCTAssertEqual(model.text, "loaded")
    }

    func testLoadingNotesTellsNoOne() {
        let (model, observer) = makeObservedModel()

        model.loadNotes([day("2026-10-28"): "loaded"])

        XCTAssertEqual(observer.events, [])
    }

    func testObserverLoadingInsideRangeChangeLeavesModelConsistent() {
        let (model, observer) = makeObservedModel()
        observer.onRangeChanged = { model.loadNotes([self.day("2026-11-04"): "next week"]) }

        model.nextRange()

        XCTAssertEqual(model.selected, day("2026-10-28"))
        model.select(day("2026-11-04"))
        XCTAssertEqual(model.text, "next week")
        XCTAssertEqual(observer.events.count, 2)
    }

    func testSelectedDayKeepsItsTextWhileAnotherRangeIsLoaded() {
        let model = makeModel()
        model.text = "mine"
        model.nextRange()

        model.loadNotes([day("2026-11-04"): "next week"])

        XCTAssertEqual(model.text, "mine")
        model.select(day("2026-11-04"))
        XCTAssertEqual(model.text, "next week")
    }

    func testModelDoesNotKeepItsObserverAlive() {
        let model = makeModel()
        weak var weakObserver: RecordingObserver?
        autoreleasepool {
            let observer = RecordingObserver()
            weakObserver = observer
            model.observer = observer
        }

        XCTAssertNil(weakObserver)
    }

    private func makeObservedModel() -> (NoteRangeModel, RecordingObserver) {
        let model = makeModel()
        let observer = RecordingObserver()
        model.observer = observer
        observerKeeper = observer
        observer.events = []
        return (model, observer)
    }
}

enum ObservedEvent: Equatable {
    case edited(Day, String)
    case selected(Day)
    case range(Day, Day)
}

final class RecordingObserver: NoteRangeObserver {
    var events: [ObservedEvent] = []
    var onRangeChanged: () -> Void = {}

    func textEdited(day: Day, text: String) {
        events.append(.edited(day, text))
    }

    func selectionChanged(to day: Day) {
        events.append(.selected(day))
    }

    func rangeChanged(from first: Day, to last: Day) {
        events.append(.range(first, last))
        onRangeChanged()
    }
}
