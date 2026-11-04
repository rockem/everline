# US-3 Daily Notes With a Weekday Strip Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The app opens on today's note, shows a seven-day strip, and gives each day its own in-memory note.

**Architecture:** A pure-Swift `NotebookModel` (an `@Observable` class) owns today, the selected day and the text of
every visited day, using an injected `Calendar` and today value. SwiftUI shows a `WeekStrip` above the existing
`NoteEditor`, which is bound to the selected day's text. The model is covered by unit tests; the UI by XCUITests that
fix "today" through a launch environment variable.

**Tech Stack:** Swift, SwiftUI, AppKit/UIKit text views, XCTest, XCUITest.

**Spec:** GitHub issue [#3](https://github.com/rockem/everline/issues/3) (US-3) and `docs/MVP-user-stories.md`.

## Global Constraints

- Minimum deployment: macOS 14.0 and iOS 17.0, so `@Observable` is available.
- Nothing is persisted: text lives in memory only (US-4 adds storage).
- Week start rule: the week starts on `calendar.firstWeekday` of the injected calendar. The app injects
  `Calendar.current`, so it follows the user's system setting. Unit tests use fixed calendars.
- Anchor rule: the anchor date is the selected day. The strip shows the seven days of the week containing it.
- Previous and next move the selection by exactly 7 calendar days, so the highlighted day is always in the strip.
- Day arithmetic uses `Calendar` date components, never `86_400`-second offsets.
- Accessibility identifiers: `day-YYYY-MM-DD`, `previous-week`, `next-week`, and the existing `note-editor`.
- Test override: the environment variable `EVERLINE_TODAY=YYYY-MM-DD` replaces the real date at launch.

## Review Focus

- Weeks crossing a month or year boundary (for example Dec 29 to Jan 4) list seven consecutive days in order.
- A calendar whose first weekday is Sunday versus Monday produces different weeks for the same date.
- A week containing a daylight-saving change still has seven distinct days.
- Cmd-Z after switching days must not bring back the previous day's text into the new day.
- Clicking a day or an arrow must leave keyboard focus in the editor, so typing continues without a click.

---

## Task 1: Unit test target and week computation

**Files:**

- Modify: `everline.xcodeproj/project.pbxproj` (new `everlineTests` unit test target, hand-edited like
  `everlineUITests`; macOS only, deployment target 14.0, host app `everline`)
- Create: `everline/Day.swift`, `everlineTests/DayTests.swift`

**Interfaces:**

- Produces: `struct Day: Hashable, Comparable, Identifiable` with
  - `init(_ date: Date, calendar: Calendar)`
  - `init?(isoString: String, calendar: Calendar)` parsing `YYYY-MM-DD`
  - `var id: String` formatted `YYYY-MM-DD`
  - `func date(in calendar: Calendar) -> Date` (start of that day)
  - `func adding(days: Int, in calendar: Calendar) -> Day`
  - `func week(in calendar: Calendar) -> [Day]` (seven days starting at `calendar.firstWeekday`)

- [ ] **Step 1: Add the unit test target**

  Add `everlineTests` to `project.pbxproj` by hand, mirroring how `everlineUITests` was added, with the app as the
  host. Add a placeholder `DayTests` with an empty `XCTestCase` so the target builds. Add the scheme's test action
  for it.
  Run: `make test`. Expected: the UI tests and the placeholder pass.

- [ ] **Step 2: Write the failing tests** in `DayTests`, using a Gregorian calendar with an explicit `firstWeekday`
  and `timeZone`

  - `testWeekStartsOnMondayWhenCalendarSaysSo`: `2026-10-28.week(in: monday)` equals 2026-10-26 to 2026-11-01.
  - `testWeekStartsOnSundayWhenCalendarSaysSo`: the same day gives 2026-10-25 to 2026-10-31.
  - `testWeekCrossingYearBoundary`: `2026-12-31` with a Monday calendar gives 2026-12-28 to 2027-01-03, in order.
  - `testWeekAcrossDaylightSavingChange`: in `America/New_York`, the week of 2026-11-01 (clocks go back) has seven
    distinct days, 2026-10-26 to 2026-11-01 with Monday start.
  - `testAddingDaysCrossesMonths`: `2026-10-31.adding(days: 1)` is 2026-11-01; `adding(days: -7)` of 2026-11-01 is
    2026-10-25.
  - `testIsoStringRoundTrip`: `Day(isoString: "2026-10-28")?.id == "2026-10-28"`; `Day(isoString: "nope")` is nil.

- [ ] **Step 3: Run the tests to verify they fail**

  Run: `make test`. Expected: compile failure, `Day` is not defined.

- [ ] **Step 4: Implement `Day` in `everline/Day.swift`**

  Store `year`, `month`, `day` as `Int`. Build it from `calendar.dateComponents`. `week(in:)` computes the offset of
  the day's weekday from `calendar.firstWeekday` and returns seven consecutive `adding(days:)` results.

- [ ] **Step 5: Run the tests to verify they pass**

  Run: `make test`. Expected: all PASS.

- [ ] **Step 6: Commit**

  ```bash
  git add -A && git commit -m "feat: [#3] Day value type with week computation"
  ```

## Task 2: Notebook model

**Files:**

- Create: `everline/NotebookModel.swift`, `everlineTests/NotebookModelTests.swift`

**Interfaces:**

- Consumes: `Day` from Task 1.
- Produces: `@Observable final class NotebookModel` with
  - `init(today: Day, calendar: Calendar)`
  - `let today: Day`
  - `private(set) var selected: Day` (initially `today`)
  - `var weekDays: [Day] { get }` (the selected day's week)
  - `var text: String { get set }` (the selected day's note, `""` when never written)
  - `func select(_ day: Day)`
  - `func showNextWeek()` and `func showPreviousWeek()` (selection moves by 7 days)

- [ ] **Step 1: Write the failing tests** in `NotebookModelTests`, Monday calendar, today 2026-10-28

  - `testOpensOnToday`: `selected == today` and `text == ""`.
  - `testWeekDaysContainSelectedDay`: `weekDays` has 7 entries, includes `selected`, first is 2026-10-26.
  - `testEachDayKeepsItsOwnText`: write "a" on today, select 2026-10-29, write "b", select today: text is "a";
    select 2026-10-29: text is "b".
  - `testNextWeekMovesSelectionBySevenDays`: `selected == 2026-11-04` and `weekDays.first == 2026-11-02`.
  - `testPreviousWeekThenNextWeekReturnsToSameDayWithItsText`: write "x" on today, previous, next: selected is today
    and text is "x".
  - `testTextOfAnotherWeekIsNotLost`: write "x" on today, next week, write "y", previous week: text is "x".

- [ ] **Step 2: Run the tests to verify they fail**

  Run: `make test`. Expected: compile failure, `NotebookModel` is not defined.

- [ ] **Step 3: Implement `NotebookModel`**

  Keep `private var notes: [Day: String]`. `text` reads and writes `notes[selected, default: ""]`. Do not store empty
  strings, so visiting a day does not create a note.

- [ ] **Step 4: Run the tests to verify they pass**

  Run: `make test`. Expected: all PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add -A && git commit -m "feat: [#3] Notebook model with per-day text and week navigation"
  ```

## Task 3: Weekday strip and per-day editor

**Files:**

- Create: `everline/WeekStrip.swift`
- Modify: `everline/NoteEditor.swift`, `everline/ContentView.swift`, `everline/MyApp.swift`,
  `everlineUITests/NoteEditorUITests.swift`

**Interfaces:**

- Consumes: `NotebookModel`, `Day` from Tasks 1 and 2.
- Produces:
  - `struct WeekStrip: View` taking `model: NotebookModel`, with a button per day (identifier `day-YYYY-MM-DD`,
    label like "Wednesday 28, today" for today, selected state via the `.isSelected` trait) and buttons
    `previous-week` and `next-week`.
  - `NoteEditor(text: Binding<String>)` replacing the no-argument initializer.
  - `NotebookModel.makeDefault()`: a static factory that reads `EVERLINE_TODAY`, falling back to the real date, with
    `Calendar.current`.

- [ ] **Step 1: Write the failing UI tests** in `NoteEditorUITests`, launching with
  `app.launchEnvironment["EVERLINE_TODAY"] = "2026-10-28"` (add this to `setUpWithError`)

  - `testOpensOnTodayWithSevenDaysShown`: `day-2026-10-28` is selected; `day-2026-10-26` and `day-2026-11-01` exist
    (Monday-start locale assumed: set `-AppleFirstWeekday '{gregorian = 2;}'` in `launchArguments`); the today
    button's label contains "today".
  - `testEachDayKeepsItsOwnText`: type "monday note", click `day-2026-10-29`, assert the editor value is `""`, type
    "tuesday note", click `day-2026-10-28`, assert "monday note".
  - `testNextAndPreviousArrowsMoveByWeek`: click `next-week`; `day-2026-11-04` is selected and `day-2026-11-01` is
    gone; click `previous-week`; `day-2026-10-28` is selected.
  - `testFocusStaysInEditorAfterSwitchingDay` (Review Focus): click `day-2026-10-29` then type "x" without clicking
    the editor; assert the editor value is "x".
  - `testUndoAfterSwitchingDayDoesNotRestoreOtherDaysText` (Review Focus): type "abc", click the next day, press
    Cmd-Z, assert the editor value is `""`, click back and assert "abc".
  - Update the existing tests only where `setUp` changes require it.

- [ ] **Step 2: Run the tests to verify they fail**

  Run: `make test`. Expected: the new tests FAIL (no strip elements); the old tests still pass.

- [ ] **Step 3: Implement the view layer**

  - `NoteEditor`: add a coordinator as the text view delegate to push edits into the binding; in
    `updateNSView`/`updateUIView`, set the text only when it differs from the binding, and on a change of day call
    `undoManager?.removeAllActions()` so Cmd-Z cannot cross days (pass the selected `Day` or let the editor compare
    strings, whichever keeps the undo reset to real day changes only).
  - `WeekStrip`: a horizontal row of seven day buttons plus the two arrows, styled so selected and today differ
    visually. Buttons must not take keyboard focus (`.focusable(false)` on macOS) and must hand focus back to the
    editor, so the editor stays first responder.
  - `ContentView`: `WeekStrip` above `NoteEditor(text: $model.text)`, with the model held as `@State` created from
    `NotebookModel.makeDefault()`.
  - `MyApp`: unchanged apart from anything `ContentView` needs.

- [ ] **Step 4: Run the tests to verify they pass**

  Run: `make test`, and `xcodebuild -project everline.xcodeproj -scheme everline -destination 'generic/platform=iOS'
  CODE_SIGNING_ALLOWED=NO build`. Expected: all macOS tests PASS and the iOS build succeeds.

- [ ] **Step 5: Commit and open the pull request**

  ```bash
  git add -A && git commit -m "feat: [#3] Weekday strip with a note per day"
  ```

  Open a pull request that closes #3 and check off the acceptance criteria in the issue.
