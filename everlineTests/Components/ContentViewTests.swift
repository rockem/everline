import AppKit
import SwiftUI
import XCTest
@testable import everline

@MainActor
final class ContentViewTests: XCTestCase {
    private var hosted: HostedView<ContentView>!
    private var model: NotebookModel!

    override func setUp() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(identifier: "UTC")!
        model = NotebookModel(today: Day(2026, 10, 28), calendar: DayCalendar(calendar))
        hosted = HostedView(ContentView(model: model), size: CGSize(width: 700, height: 500))
        hosted.settle()
    }

    override func tearDown() {
        hosted.close()
        hosted = nil
        model = nil
    }

    func testUndoAfterSwitchingDayDoesNotRestoreOtherDaysText() {
        type("abc")
        show("2026-10-29")

        editor.undoManager?.undo()
        hosted.settle()

        XCTAssertEqual(editor.string, "")
        show("2026-10-28")
        XCTAssertEqual(editor.string, "abc")
    }

    private func type(_ text: String) {
        editor.insertText(text, replacementRange: NSRange(location: NSNotFound, length: 0))
        hosted.settle()
    }

    private var editor: NSTextView {
        hosted.find(NSTextView.self)!
    }

    private func show(_ iso: String) {
        model.select(Day(iso: iso)!)
        hosted.settle()
    }
}
