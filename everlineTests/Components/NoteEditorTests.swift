import AppKit
@testable import everline
import SwiftUI
import XCTest

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

    func testTypedTextUsesTheNoteTypography() {
        let textView = host()

        type("abc", into: textView)

        assertTypography(of: textView, at: 0)
    }

    func testInitialTextUsesTheNoteTypography() {
        box.text = "saved text"
        let textView = host()

        assertTypography(of: textView, at: 0)
    }

    func testTextSetFromOutsideUsesTheNoteTypography() {
        let textView = host()

        box.text = "changed elsewhere"
        hosted.update(NoteEditor(text: box.binding))
        hosted.settle()

        assertTypography(of: textView, at: 0)
    }

    private func assertTypography(of textView: NSTextView, at index: Int, file: StaticString = #filePath,
                                  line: UInt = #line) {
        let attributes = textView.textStorage?.attributes(at: index, effectiveRange: nil) ?? [:]
        let font = attributes[.font] as? NSFont
        let style = attributes[.paragraphStyle] as? NSParagraphStyle
        XCTAssertEqual(font?.fontName, NoteTypography.fontName, file: file, line: line)
        XCTAssertEqual(font?.pointSize, NoteTypography.size, file: file, line: line)
        XCTAssertEqual(style?.minimumLineHeight ?? 0, NoteTypography.size * 1.8, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(style?.maximumLineHeight ?? 0, NoteTypography.size * 1.8, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(attributes[.kern] as? CGFloat ?? 0, -0.16, accuracy: 0.001, file: file, line: line)
    }

    func testTextIsCenteredInItsLine() throws {
        box.text = "abc"
        let textView = host()
        let layout = try XCTUnwrap(textView.layoutManager)
        let font = NoteTypography.font
        let extra = NoteTypography.size * 1.8 - (font.ascender - font.descender)

        let baseline = layout.location(forGlyphAt: 0).y

        XCTAssertEqual(baseline, extra / 2 + font.ascender, accuracy: 0.5)
    }

    func testCaretIsAsTallAsTheFontAndCentered() {
        let line = NSRect(x: 10, y: 0, width: 1, height: NoteTypography.size * 1.8)
        let font = NoteTypography.font

        let caret = NoteTypography.caretRect(in: line)

        XCTAssertEqual(caret.height, font.ascender - font.descender, accuracy: 0.01)
        XCTAssertEqual(caret.midY, line.midY, accuracy: 0.01)
        XCTAssertEqual(caret.minX, line.minX)
        XCTAssertEqual(caret.width, line.width)
    }

    func testShowsThePlaceholderOnlyWhileEmpty() throws {
        let textView = try XCTUnwrap(host() as? NoteTextView)
        XCTAssertEqual(textView.accessibilityPlaceholderValue(), NoteTypography.placeholder)
        XCTAssertTrue(textView.isShowingPlaceholder)

        type("a", into: textView)

        XCTAssertFalse(textView.isShowingPlaceholder)
    }

    func testUpdatesWhenBindingChanges() {
        let textView = host()

        box.text = "changed elsewhere"
        hosted.update(NoteEditor(text: box.binding))
        hosted.settle()

        XCTAssertEqual(textView.string, "changed elsewhere")
    }
}
