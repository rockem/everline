import XCTest

@MainActor
final class NoteEditorUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchEditor() -> XCUIElement {
        let app = XCUIApplication()
        app.launch()
        let editor = app.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5), "note editor is not on screen")
        editor.click()
        return editor
    }

    func testTypingShowsTextInNote() {
        let editor = launchEditor()

        editor.typeText("Hello Everline")

        XCTAssertEqual(editor.value as? String, "Hello Everline")
    }

    func testUndoRemovesTypedText() {
        let editor = launchEditor()

        editor.typeText("abc")
        editor.typeKey("z", modifierFlags: .command)

        XCTAssertEqual(editor.value as? String, "")
    }
}
