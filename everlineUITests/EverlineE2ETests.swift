import XCTest

/// Whole-app flows only. Single components are covered by the in-process tests in `everlineTests`.
@MainActor
final class EverlineE2ETests: XCTestCase {
    private var app: XCUIApplication!

    private var editor: XCUIElement!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["EVERLINE_TODAY"] = "2026-10-28"
        // A fresh folder per test (a relative name lands in the app's temporary directory): the real notebook is never
        // touched and tests don't see each other's notes.
        app.launchEnvironment["EVERLINE_DIR"] = "e2e-\(UUID().uuidString)"
        app.launch()
        editor = app.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5), "note editor is not on screen")
    }

    func testNewWindowShortcutDoesNotOpenSecondWindow() {
        app.typeKey("n", modifierFlags: .command)

        XCTAssertEqual(app.windows.count, 1)
    }

    func testWritingAcrossTwoDays() {
        editor.typeText("monday note")
        dayButton("2026-10-29").click()
        XCTAssertEqual(editor.value as? String, "")

        editor.typeText("tuesday note")
        dayButton("2026-10-28").click()
        XCTAssertEqual(editor.value as? String, "monday note")

        app.buttons["next-week"].click()
        XCTAssertFalse(dayButton("2026-11-04").isSelected)
        XCTAssertEqual(editor.value as? String, "monday note")
        dayButton("2026-11-04").click()
        XCTAssertEqual(editor.value as? String, "")
        app.buttons["previous-week"].click()
        XCTAssertFalse(dayButton("2026-10-28").isSelected)
        dayButton("2026-10-28").click()
        XCTAssertEqual(editor.value as? String, "monday note")
    }

    private func dayButton(_ iso: String) -> XCUIElement {
        app.buttons["day-\(iso)"]
    }
}
