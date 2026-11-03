import AppKit
import SwiftUI
import XCTest
@testable import everline

@MainActor
final class NoteEditorTests: XCTestCase {
    private final class Box {
        var text: String

        init(_ text: String) {
            self.text = text
        }

        var binding: Binding<String> {
            Binding(get: { self.text }, set: { self.text = $0 })
        }
    }

    private let box = Box("")
    private var hosted: HostedView<NoteEditor>!

    override func tearDown() {
        hosted?.close()
        hosted = nil
    }

    func testTypingUpdatesBinding() {
        let textView = host()

        type("Hello Everline", into: textView)

        XCTAssertEqual(box.text, "Hello Everline")
    }

    private func host() -> NSTextView {
        hosted = HostedView(NoteEditor(text: box.binding))
        hosted.settle()
        return hosted.find(NSTextView.self)!
    }

    private func type(_ text: String, into textView: NSTextView) {
        textView.insertText(text, replacementRange: NSRange(location: NSNotFound, length: 0))
        hosted.settle()
    }

    func testUndoRemovesTypedText() {
        let textView = host()
        type("abc", into: textView)

        textView.undoManager?.undo()
        hosted.settle()

        XCTAssertEqual(box.text, "")
    }

    func testTakesFocusWhenShown() {
        let textView = host()

        XCTAssertTrue(hosted.window.firstResponder === textView)
    }

    func testShowsInitialText() {
        box.text = "saved text"
        let textView = host()

        XCTAssertEqual(textView.string, "saved text")
    }

    func testUpdatesWhenBindingChanges() {
        let textView = host()

        box.text = "changed elsewhere"
        hosted.update(NoteEditor(text: box.binding))
        hosted.settle()

        XCTAssertEqual(textView.string, "changed elsewhere")
    }
}
