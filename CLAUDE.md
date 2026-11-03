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
- Lint everything: `pre-commit run --all-files` (needs Docker for the SwiftLint image). SwiftLint alone:
  `swiftlint lint --strict --quiet`. Markdown is wrapped at 120 columns (`.markdownlint.json`).

Two test layers:

- `everlineTests` (hosted in the app, in-process, fast; only this target can `@testable import everline`):
  - `Unit/`: `DayCalendar` and `NotebookModel` logic.
  - `Components/`: `NoteEditor` in a real `NSWindow` (`Support/HostedView`), `WeekStrip` through ViewInspector (the
    only third-party dependency, test target only), and `ContentView` with an injected model.
  - `Support/`: shared test helpers.
- `everlineUITests` (XCUITest, the real app, needs an unlocked desktop session): three whole-flow tests only. They
  fix "today" with the `EVERLINE_TODAY=YYYY-MM-DD` launch environment variable.

Add behavior tests at the component layer; add an e2e test only for flows that need the real app.

## Architecture

- One multiplatform app target `everline` (macOS and iOS). The Xcode project uses synchronized folder groups
  (`objectVersion = 90`): new files under `everline/`, `everlineTests/`, `everlineUITests/` need no `project.pbxproj`
  edits. Adding a target does, by hand.
- `NotebookModel` (`@Observable`) owns today, the selected day, and the in-memory text of every written day. It takes
  an injected `DayCalendar`, so week logic is unit-tested with fixed calendars. The week starts on
  `calendar.firstWeekday`, which the app takes from `Calendar.current` (the system setting). Navigation moves the
  selection by 7 days, so the highlighted day is always in the strip. Nothing is persisted yet (US-4 adds GRDB).
- `Day` is a time-zone-independent year/month/day value (pure data). `DayCalendar` wraps a `Calendar` and does the
  day arithmetic and week computation; never use 86 400-second offsets.
- `NoteEditor` wraps `NSTextView` (macOS) or `UITextView` (iOS) behind one `text: Binding<String>` API, selected with
  `#if os(macOS)`. The text view takes focus when it joins a window, edits (including undo) reach the binding through
  the text storage, and each editor has its own `UndoManager` because the window's shared one would hold actions
  for text views that were already replaced. `ContentView` puts `.id(model.selected)` on it, so each day gets a fresh
  text view: its own undo history while you stay on the day (lost when you leave), and focus on creation.
- `MyApp` uses a single `Window` on macOS (no Cmd-N second window) and a `WindowGroup` on iOS (`Window` is unavailable
  there).
- `Theme` holds the palette as light/dark dynamic colors. Light values come from the US-3 mockup in the issue.
- Tests locate elements by accessibility identifier: `note-editor`, `day-YYYY-MM-DD`, `previous-week`, `next-week`.

## Delivery

- CI: `precommit.yml` (Ubuntu, runs the hooks), `test.yml` (macOS, `make test`), `release.yml` (runs when a GitHub
  Release is published; builds with the tag's numeric part, attaches `Everline-<version>.zip`). Builds are unsigned
  and not notarized; the build number is the CI run number.
- Tags like `v1.2.3-rc.1` are packaged as version `1.2.3`; the zip keeps the full tag on the release.
