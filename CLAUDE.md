# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Everline is a date-first notebook: SwiftUI shell, AppKit/UIKit text view, macOS 14 and iOS 17 minimum. Product intent is
in `docs/PRD.md` and `docs/MVP.md`. Work is tracked as GitHub issues (US-1, US-2, ...), one small complete feature each,
with plans in `docs/superpowers/plans/`.

## Commands

- Test everything (unit and UI, macOS only): `make test`
- One test: `xcodebuild test -project everline.xcodeproj -scheme everline -destination 'platform=macOS'
  -only-testing:everlineTests/DayCalendarTests/testWeekCrossingYearBoundary`
  (use `everlineUITests/EverlineE2ETests/<name>` for e2e tests)
- iOS compile check (no iOS tests exist): `xcodebuild -project everline.xcodeproj -scheme everline
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
- Package an unsigned release zip: `make package VERSION=0.0.1 BUILD=1` (VERSION must be `MAJOR.MINOR.PATCH`)
- Editor LSP setup (Neovim etc.; needs `xcode-build-server`): `make buildserver`, then build once and restart the LSP
- Lint everything: `pre-commit run --all-files` (needs Docker for the SwiftLint image). SwiftLint alone:
  `swiftlint lint --strict --quiet`. Markdown is wrapped at 120 columns (`.markdownlint.json`).

Two test layers:

- `everlineTests` (hosted in the app, in-process, fast; only this target can `@testable import everline`):
  - `Unit/`: `Day`, `DayCalendar`, `NoteRangeModel`, `NotePersistor`, `RetryingNoteStore` and `Notebook` logic, with a
    `FakeNoteStore` from `Support/`.
  - `SQLite/`: `NotebookDatabase`, `Migrations` and `SQLiteNoteStore` against a real SQLite file in a temporary
    folder per test (`DatabaseFileTestCase`, which also has small query helpers; no in-memory database).
  - `Components/`: `NoteEditor` in a real `NSWindow` (`Support/HostedView`), `WeekStrip` through ViewInspector (a
    third-party dependency of the test target only), `PageHeader`, and `ContentView` with an injected model.
  - `Support/`: shared test helpers.
- `everlineUITests` (XCUITest, the real app, needs an unlocked desktop session): three whole-flow tests only. They
  fix "today" with the `EVERLINE_TODAY=YYYY-MM-DD` launch environment variable and point `EVERLINE_DIR` at a fresh
  folder name per test so they never touch the real notebook (a relative name lands in the sandboxed app's temporary
  directory).

Add behavior tests at the component layer; add an e2e test only for flows that need the real app.

## Architecture

The big picture (components, flows, diagrams) is in `docs/ARCHITECTURE.md`; update it when those change.

- One multiplatform app target `everline` (macOS and iOS). The Xcode project uses synchronized folder groups
  (`objectVersion = 90`): new files under `everline/`, `everlineTests/`, `everlineUITests/` need no `project.pbxproj`
  edits. Adding a target does, by hand.
- `NoteRangeModel` (`@Observable`) is passive: it owns today, the selected day, a range of days (today the week of a
  range anchor) and the notes of that range plus the selected day, and tells its weak `NoteRangeObserver` about edits,
  selection changes and range changes (`textEdited`, `selectionChanged`, `rangeChanged`, synchronously, with the data in
  the call; attaching an observer reports the current range). It takes an injected `DayCalendar`, so week logic is
  unit-tested with fixed calendars. The week starts on
  `calendar.firstWeekday`, which the app takes from `Calendar.current` (the system setting). `nextRange()` and
  `previousRange()` move the range by 7 days and keep the selection, which may then lie outside the range (the strip
  highlights nothing); selecting a day moves the range to it.
- `NotePersistor` is the model's observer and owns the load/save policy: it keeps the edits not yet saved (a failed save
  stays unsaved, is retried after the next pause and shows through every load), writes them when the selection or the
  range moves, after a pause in typing (2 seconds) or at a deadline while typing goes on (5 seconds, an `AutosaveTimer`
  on an injected `Scheduler`), and on `flush()`; it loads the notes of a range into the model (`loadNotes`) when it
  changes. `RetryingNoteStore` wraps the store: a failed call is retried, then the give-up handler runs (the app crashes
  on purpose). `Notebook` is the composition root, keeps model and persistor alive and offers `flush()` for "the app is
  leaving": on macOS an `ExitFlusher` calls it on quit and window close, on iOS `MyApp` calls it when the scene leaves
  `active`. `Notebook.makeDefault()` opens the SQLite file; the shared `everline` scheme sets `EVERLINE_DIR=unit-tests`
  for the test action, because the hosted unit tests launch the app, so they never open the real notebook.
- `Day` is a time-zone-independent year/month/day value (pure data). `DayCalendar` wraps a `Calendar` and does the
  day arithmetic and week computation; never use 86 400-second offsets.
- `NoteStore` (`notes(scope:from:to:)`, `save(_:for:)`) is where notes live; everything specific to SQLite and GRDB
  lives in `everline/SQLite/`. `SQLiteNoteStore` implements it with plain SQL (GRDB, pinned exactly, is the only
  third-party package in the app target, used as a thin toolkit, no ORM). `NotebookDatabase` opens the file and runs
  the migrations before the store gets the connection. A migration is one SQL file in `everline/SQLite/Migrations/`
  named `NNNN-description.sql`; `Migrations` loads the bundled files in order and registers each with GRDB's
  `DatabaseMigrator`. Never edit a shipped file, add the next number. `notes` rows have a UUID `id`, `scope`
  (nullable: day, week, month, year, or none for ranges and undated notes) and inclusive `start_date`/`end_date`; one
  note per scope and period. Saving empty text deletes the row. `Notebook` wires it to the model.
- `NoteEditor` wraps `NSTextView` (macOS) or `UITextView` (iOS) behind one `text: Binding<String>` API, selected with
  `#if os(macOS)`. The text view takes focus when it joins a window, edits (including undo) reach the binding through
  the text storage, and each editor has its own `UndoManager` because the window's shared one would hold actions
  for text views that were already replaced. `ContentView` puts `.id(model.selected)` on it, so each day gets a fresh
  text view: its own undo history while you stay on the day (lost when you leave), and focus on creation.
- `MyApp` uses a single `Window` on macOS (no Cmd-N second window) with a hidden title bar (`ContentView` keeps a 28 pt
  band above the strip for the window buttons and ignores the top safe area) and a `WindowGroup` on iOS (`Window` is
  unavailable there).
- `Theme` holds the palette as light/dark dynamic colors, sampled from the issue #21 mockups. Colors for the native text
  views are platform colors (`PlatformColor`), the rest are SwiftUI `Color`s. Text that carries meaning is at least
  4.5:1 against the background; the placeholder is deliberately fainter (about 3:1).
- Fonts are bundled in `everline/Fonts/` (Manrope for the interface, IBM Plex Mono for notes, both OFL with their
  licenses next to them) and registered in `Fonts.register()` at launch, the same way on both platforms. UI sizes are
  `@ScaledMetric` values through `Fonts.ui(_:_:relativeTo:)`, so they follow Dynamic Type. `NoteTypography` holds the
  note text numbers (16 pt, line height 1.8, letter spacing -0.01 em, the placeholder text) and the platform attributes
  both text views apply to all text and to the typing attributes.
- `PageHeader` shows the selected day as a large title; the header and the editor share one centered column (680 pt at
  most). The text view draws the empty-page placeholder itself (a label on iOS), so it lines up with the real text. Note
  text is centered in its 1.8 line height with `baselineOffset`, and the caret is cut down to the font height
  (`NoteTypography.caretRect(in:)`).
- Tests locate elements by accessibility identifier: `note-editor`, `day-YYYY-MM-DD`, `previous-week`, `next-week`,
  `note-dot` (the dot under a day whose note has text), `page-title`.

## Delivery

- CI: `precommit.yml` (Ubuntu, runs the hooks), `test.yml` (macOS, `make test`), `release.yml` (runs when a GitHub
  Release is published; builds with the tag's numeric part, attaches `Everline-<version>.zip`). Builds are unsigned
  and not notarized; the build number is the CI run number.
- Tags like `v1.2.3-rc.1` are packaged as version `1.2.3`; the zip keeps the full tag on the release.
