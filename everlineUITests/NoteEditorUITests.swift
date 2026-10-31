import XCTest

@MainActor
final class NoteEditorUITests: XCTestCase {
    private var app: XCUIApplication!
    private var editor: XCUIElement!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        editor = app.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5), "note editor is not on screen")
    }

    func testTypingShowsTextInNote() {
        editor.typeText("Hello Everline")

        XCTAssertEqual(editor.value as? String, "Hello Everline")
    }

    func testUndoRemovesTypedText() {
        editor.typeText("abc")
        editor.typeKey("z", modifierFlags: .command)

        XCTAssertEqual(editor.value as? String, "")
    }

    func testNewWindowShortcutDoesNotOpenSecondWindow() {
        app.typeKey("n", modifierFlags: .command)

        XCTAssertEqual(app.windows.count, 1)
    }
}
