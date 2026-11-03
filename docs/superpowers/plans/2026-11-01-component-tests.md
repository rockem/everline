# Component Tests and a Slim E2E Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Test each UI component in isolation, in-process and fast, and keep only whole-flow tests as XCUITest e2e.

**Architecture:** Component tests live in the hosted `everlineTests` target. They put one SwiftUI or AppKit component
in an `NSWindow`, drive it through its real controls (text view input, accessibility actions) and assert on the model
or the view. `everlineUITests` keeps three tests that need the real app: launch focus and typing, the single-window
rule, and one multi-day flow.

**Tech Stack:** Swift, XCTest, AppKit, SwiftUI `NSHostingView`, XCUITest.

**Spec:** the current `everlineUITests/NoteEditorUITests.swift` (behavior to preserve) and `CLAUDE.md`.

## Global Constraints

- macOS only; there are no iOS tests today and none are added.
- No new third-party dependency unless Task 2's fallback ruling applies.
- Every behavior asserted by a current UI test must still be asserted somewhere after this plan.
- `make test` still runs everything; no new Makefile targets.
- Production code changes are limited to dependency injection that tests need: `ContentView(model:)`.

## Review Focus

- A component test that passes while the real wiring is broken (for example `ContentView` not passing the binding):
  the e2e flow test must catch it.
- First-responder focus in a hosted window: it must be asserted after the run loop has turned, not synchronously.
- Component tests must not depend on the user's system week-start setting.
- Hosted tests run inside the real app process: a leaked window from one test must not affect the next.

---

## Task 1: Hosting helper and NoteEditor component tests

**Files:**

- Create: `everlineTests/Support/HostedView.swift`, `everlineTests/NoteEditorTests.swift`

**Interfaces:**

- Produces: `@MainActor final class HostedView<Content: View>` with
  - `init(_ content: Content, size: CGSize = CGSize(width: 700, height: 500))` that puts the view in a key `NSWindow`
  - `func settle()` that spins the run loop briefly so deferred work (focus) happens
  - `func find<T: NSView>(_ type: T.Type) -> T?` (first matching subview)
  - `func close()` (use in `tearDown`)

- [ ] **Step 1: Write the failing tests** in `NoteEditorTests` (host `NoteEditor(text:)` with a `Binding` backed by a
  local variable)

  - `testTypingUpdatesBinding`: insert "Hello Everline" with `textView.insertText(_:replacementRange:)`; the bound
    value equals "Hello Everline".
  - `testUndoRemovesTypedText`: insert "abc", `textView.undoManager?.undo()`; the bound value is `""`.
  - `testTakesFocusWhenShown`: after `settle()`, `window.firstResponder === textView`.
  - `testShowsInitialText`: host with "saved text"; `textView.string == "saved text"`.
  - `testUpdatesWhenBindingChanges`: change the bound value from outside and re-render; `textView.string` follows.

- [ ] **Step 2: Run to verify they fail**

  Run: `make test`. Expected: compile failure, `HostedView` is not defined.

- [ ] **Step 3: Implement `HostedView`** as described in Interfaces, using `NSHostingView` as the window's content.

- [ ] **Step 4: Run to verify they pass**

  Run: `make test`. Expected: the five new tests pass and the old UI tests still pass.

- [ ] **Step 5: Commit**

  ```bash
  git add -A && git commit -m "test: hosted NoteEditor component tests"
  ```

## Task 2: WeekStrip component tests

**Files:**

- Create: `everlineTests/Support/AccessibilityTree.swift`, `everlineTests/WeekStripTests.swift`

**Interfaces:**

- Consumes: `HostedView` from Task 1; `NotebookModel`, `Day`.
- Produces: `func element(withIdentifier: String, in view: NSView) -> NSAccessibilityElementProtocol?` plus
  helpers to read its label and selected state and to press it, built on the hosted view's accessibility children.

- [ ] **Step 1: Write the failing tests** in `WeekStripTests`, each building a `NotebookModel` with a fixed
  calendar (today 2026-10-28)

  - `testShowsSevenDaysStartingOnMonday`: identifiers `day-2026-10-26` to `day-2026-11-01` exist, `day-2026-10-25`
    does not (Monday calendar).
  - `testShowsSevenDaysStartingOnSunday`: first is `day-2026-10-25` (Sunday calendar).
  - `testSelectedDayIsMarkedSelected`: only `day-2026-10-28` is selected.
  - `testTodayIsLabeledToday`: its label contains "today"; other days' labels do not.
  - `testPressingADaySelectsIt`: press `day-2026-10-29`; `model.selected` is 2026-10-29.
  - `testNextAndPreviousButtonsMoveByWeek`: press `next-week`; `model.selected` is 2026-11-04 and the strip
    re-renders to `day-2026-11-02` through `day-2026-11-08`; press `previous-week`; back to 2026-10-28.

- [ ] **Step 2: Run to verify they fail**

  Run: `make test`. Expected: compile failure on the accessibility helpers.

- [ ] **Step 3: Implement the accessibility helpers**

  Walk `NSAccessibilityProtocol.accessibilityChildren()` from the hosted view, matching
  `accessibilityIdentifier()`; press with `accessibilityPerformPress()`. Spin the run loop after each press.

  Ruling to apply if the hosted SwiftUI accessibility tree does not expose identifiers or press actions in-process:
  add ViewInspector as a Swift package dependency of `everlineTests` only, pin an exact version, and drive the same
  assertions through it. Ledger the ruling and the reason.

- [ ] **Step 4: Run to verify they pass**

  Run: `make test`. Expected: the six new tests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add -A && git commit -m "test: WeekStrip component tests"
  ```

## Task 3: ContentView integration tests

**Files:**

- Modify: `everline/ContentView.swift` (add `init(model: NotebookModel = .makeDefault())`)
- Create: `everlineTests/ContentViewTests.swift`

**Interfaces:**

- Consumes: `HostedView`, the accessibility helpers, `NotebookModel`.
- Produces: `ContentView(model:)`, so tests inject a model with a fixed calendar and today.

- [ ] **Step 1: Write the failing tests** hosting `ContentView(model:)`

  - `testEachDayKeepsItsOwnText`: type "monday note", press `day-2026-10-29`, the editor is empty, type
    "tuesday note", press `day-2026-10-28`, the editor shows "monday note".
  - `testFocusStaysInEditorAfterSwitchingDay`: press a day, `settle()`, `firstResponder` is the new text view.
  - `testUndoAfterSwitchingDayDoesNotRestoreOtherDaysText`: type "abc", press the next day, undo on the new text
    view, it stays empty; press back, it shows "abc".

- [ ] **Step 2: Run to verify they fail**

  Run: `make test`. Expected: compile failure, `ContentView` has no `init(model:)`.

- [ ] **Step 3: Implement the initializer**

  Store the injected model in `@State` through its initial value, so the default path is unchanged.

- [ ] **Step 4: Run to verify they pass**

  Run: `make test`. Expected: the three new tests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add -A && git commit -m "test: ContentView integration tests with injected model"
  ```

## Task 4: Slim the XCUITest suite

**Files:**

- Modify: `everlineUITests/NoteEditorUITests.swift` (rename the class to `EverlineE2ETests` and the file to
  `EverlineE2ETests.swift`), `CLAUDE.md`

**Interfaces:**

- Consumes: everything above, as the replacement coverage.

- [ ] **Step 1: Write the new e2e test** `testWritingAcrossTwoDays`: launch, type "monday note" without clicking,
  click `day-2026-10-29`, type "tuesday note", click `day-2026-10-28`, assert "monday note", click
  `next-week` then `previous-week`, assert the selected day is today's. This proves the real wiring end to end.

- [ ] **Step 2: Run to verify it passes**

  Run: `make test`. Expected: it passes against the current app; if not, that is a wiring bug to fix first.

- [ ] **Step 3: Remove the covered UI tests**

  Delete `testUndoRemovesTypedText`, `testOpensOnTodayWithSevenDaysShown`, `testEachDayKeepsItsOwnText`,
  `testNextAndPreviousArrowsMoveByWeek`, `testFocusStaysInEditorAfterSwitchingDay` and
  `testUndoAfterSwitchingDayDoesNotRestoreOtherDaysText`. Keep `testTypingShowsTextInNote` (launch focus and
  typing) and `testNewWindowShortcutDoesNotOpenSecondWindow`. Drop the `-AppleLocale en_GB` launch argument: no
  remaining test depends on the week start. Keep `EVERLINE_TODAY`.

- [ ] **Step 4: Update `CLAUDE.md`**

  Describe the two layers: component tests in `everlineTests` (hosted, in-process) and three e2e tests in
  `everlineUITests`; remove the `en_GB` note; keep the single-test commands.

- [ ] **Step 5: Run everything and commit**

  Run: `make test` and `pre-commit run --all-files`. Expected: all pass, and the UI suite is three tests.

  ```bash
  git add -A && git commit -m "test: keep three e2e tests, move the rest to component tests"
  ```
