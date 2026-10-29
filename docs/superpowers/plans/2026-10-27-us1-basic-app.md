# US-1 Basic App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Everline launches to one window with an editable, unsaved text area, proven by end-to-end UI tests.

**Architecture:** The template's SwiftUI app hosts an AppKit `NSTextView` through `NSViewRepresentable`. XCUITests
launch the real app and find the text area by accessibility identifier.

**Tech Stack:** Swift, SwiftUI, AppKit, XCUITest.

**Spec:** GitHub issue [#1](https://github.com/rockem/everline/issues/1) (US-1) and `docs/MVP-user-stories.md`.

## Global Constraints

- Minimum deployment target: macOS 14.0 (project currently says 26.6.2).
- The app is named Everline; bundle id `io.github.rockem.Everline` (assumed from the remote; adjust if you prefer).
- Nothing is saved: no database, persistence or settings. Text is gone after quit.
- Scope is a window with an editable area: no navigation, Markdown or toolbar.

## Review Focus

- Cmd-Z after typing: must undo, which `NSTextView` only does when `allowsUndo` is set. Owned by Task 1.
- Cmd-Q with typed text: no save prompt and no crash, since nothing is saved. Owned by Task 2.

---

## Task 1: Editable text area

**Files:**

- Create: `everlineUITests/NoteEditorUITests.swift`, `everline/NoteEditor.swift`
- Modify: `everline/ContentView.swift`

**Interfaces:**

- Produces: `struct NoteEditor: NSViewRepresentable` and accessibility identifier `"note-editor"` on its
  `NSTextView`, reachable as `app.textViews["note-editor"]`. Later stories locate the editor through it.

- [ ] **Step 1: Add the UI test target (manual, in Xcode)**

  File, New, Target, macOS, UI Testing Bundle, named `everlineUITests`, target under test `everline`, signing "Sign to
  Run Locally". Delete the generated template tests. The project uses synchronized folders, so later files need no
  `project.pbxproj` edits.

- [ ] **Step 2: Write the failing tests** in `NoteEditorUITests`

  - `testTypingShowsTextInNote`: launch the app, type `"Hello Everline"` into `app.textViews["note-editor"]`, assert
    its `value as? String == "Hello Everline"`.
  - `testUndoRemovesTypedText`: type `"abc"`, press Cmd-Z, assert the value is `""`.

- [ ] **Step 3: Run tests to verify they fail**

  Run: `xcodebuild test -project everline.xcodeproj -scheme everline -destination 'platform=macOS'`
  Expected: both FAIL (the template shows "Hello, world!" and has no `note-editor` element).

- [ ] **Step 4: Implement `NoteEditor`**

  `makeNSView` returns an `NSScrollView` whose `documentView` is an editable plain-text `NSTextView` with
  `allowsUndo = true` and `setAccessibilityIdentifier("note-editor")`. `updateNSView` does nothing.
  `ContentView.body` becomes `NoteEditor()`; remove the `Playgrounds` import and `#Playground` block.

- [ ] **Step 5: Run tests to verify they pass**

  Run: the command from Step 3. Expected: 2 tests PASS.

- [ ] **Step 6: Commit**

  ```bash
  git add -A && git commit -m "feat: editable text area with typing and undo e2e tests"
  ```

## Task 2: Single window

**Files:**

- Modify: `everline/MyApp.swift`, `everlineUITests/NoteEditorUITests.swift`

**Interfaces:**

- Consumes: `ContentView` and the `"note-editor"` identifier from Task 1.

- [ ] **Step 1: Write the failing tests**

  - `testNewWindowShortcutDoesNotOpenSecondWindow`: press Cmd-N; assert `app.windows.count == 1`.
  - `testQuitWithTextHasNoPrompt`: type text, press Cmd-Q; assert `app.state == .notRunning` within 5 seconds.

- [ ] **Step 2: Run tests to verify the right one fails**

  Expected: the new-window test FAILS (the template `WindowGroup` opens a second window); the quit test passes.

- [ ] **Step 3: Switch to a single window scene**

  In `MyApp`, replace `WindowGroup` with `Window("Everline", id: "main") { ContentView() }`. A single `Window` scene
  removes the New Window command.

- [ ] **Step 4: Run all UI tests**

  Expected: all PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add -A && git commit -m "feat: single note window"
  ```

## Task 3: Naming and deployment target

**Files:**

- Modify: `everline.xcodeproj/project.pbxproj` (build settings)
- Rename: `everline/MyApp.swift` to `everline/EverlineApp.swift`

**Interfaces:**

- Produces: product `Everline.app`, bundle id `io.github.rockem.Everline`. The US-2 scripts consume the product name.

- [ ] **Step 1: Write the failing check**

  Run: `xcodebuild -project everline.xcodeproj -scheme everline -showBuildSettings | grep -E
  'MACOSX_DEPLOYMENT_TARGET|FULL_PRODUCT_NAME|PRODUCT_BUNDLE_IDENTIFIER'`
  Expected today: `26.6.2`, `everline.app`, a `devplaceholder.` id.

- [ ] **Step 2: Change the settings**

  App and UI test targets: `MACOSX_DEPLOYMENT_TARGET = 14.0`. App target: `PRODUCT_NAME = Everline`,
  `PRODUCT_BUNDLE_IDENTIFIER = io.github.rockem.Everline`, both configurations. `git mv` `MyApp.swift` to
  `EverlineApp.swift` and rename the struct to `EverlineApp`.

- [ ] **Step 3: Verify**

  Re-run Step 1: expect `14.0`, `Everline.app`, `io.github.rockem.Everline`. Re-run the UI tests: expect all PASS.

- [ ] **Step 4: Commit and open the pull request**

  ```bash
  git add -A && git commit -m "build: name the app Everline and target macOS 14"
  ```

  Open a pull request that closes #1 and check off the acceptance criteria in the issue.
