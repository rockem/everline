@testable import everline
import XCTest

final class NotebookTests: XCTestCase {
    private var store: FakeNoteStore!

    override func setUp() {
        store = FakeNoteStore()
    }

    func testOpensWithSavedNotes() {
        store.notes = [today: "saved"]

        let notebook = makeNotebook()

        XCTAssertEqual(notebook.model.text, "saved")
    }

    private func makeNotebook() -> Notebook {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return Notebook(store: store, today: today, calendar: DayCalendar(calendar))
    }

    private let today = Day(2026, 10, 28)
}
