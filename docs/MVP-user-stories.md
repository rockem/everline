# Everline — MVP 0.1 User Stories

Scope and acceptance criteria live in [MVP.md](MVP.md). Product context lives in [PRD.md](PRD.md).

Each story is a small, complete, shippable feature with its own tests, delivered through the pipeline from US-2.
Stories are ordered; each builds on the ones before it.

Priority: **Must** = required for MVP 0.1. **Should** = valuable, can slip if the schedule is tight.

## Decisions

- **Distribution:** GitHub Releases only for now. TestFlight and the Mac App Store are deferred, along with the paid
  Apple Developer account, signing and notarization they need.
- **Minimum macOS version:** macOS 14 (Sonoma). The project currently targets macOS 26.6.2, which is too high for
  real users, so US-1 lowers the deployment target to 14.0.
- **Versioning:** semantic versioning, `MAJOR.MINOR.PATCH`, from git tags. The first release ships as `0.0.1`, MVP 0.1
  as `0.1.0`, and `1.0.0` is reserved for the first public release. The build number is the CI run number.
- **Scripts:** plain shell scripts in `scripts/` wrapping `xcodebuild`, unless a task runner proves necessary.

## US-1 Basic app (Must)

As a user, I want to launch the app and see a window with an empty editable note so that there is a running app to
build on.

- Launching shows one window containing a native, editable text area. Cmd-N does not open a second window.
- Typing works, nothing is saved and the text is gone after quit.
- The app is named Everline (replacing the template's `MyApp` and "Hello, world!") and targets macOS 14.0.
- An end-to-end UI test (`everlineUITests`), written first and seen failing, launches the app, finds the text area by
  accessibility identifier, types a string and asserts the text area's value.

## US-2 Delivery pipeline (Must)

As a developer, I want build, test, lint, CI and release in place from day one so that every later story is built
test-first and ships through the same path.

- **Test:** `scripts/test.sh` wraps `xcodebuild test` and exits non-zero on any failure. A unit test target arrives
  with the first story that has real logic (US-3), not as an empty placeholder.
- **Lint:** SwiftLint (`.swiftlint.yml`) and markdownlint (existing `.markdownlint.json`) pass, run by one command such
  as `scripts/lint.sh` that fails on any violation.
- **Build:** both Debug and Release build, with compiler warnings treated as errors.
- **CI:** a GitHub Actions workflow on a macOS runner runs lint, build and test on every push and pull request, using
  the same scripts as local runs. A failing step fails the check.
- **Release:** pushing a version tag (e.g. `v0.0.1`) runs a workflow that builds Release and attaches a zipped app to
  a GitHub Release. The marketing version comes from the tag and the build number from the CI run number.
- Code signing and notarization are deferred; an unsigned build is acceptable for now and the release notes say so.

## US-3 Daily notes with a weekday strip (Must)

As a user, I want a strip of the seven days of the current week so that each day has its own note.

- The app opens on today's note. The strip always shows seven weekdays around the anchor date, with the selected day
  highlighted and Today distinguished. The week start follows a single defined rule.
- Selecting a day opens that day's own note; each day keeps its own text while the app runs, and switching days
  never mixes or loses text. Nothing is persisted yet (US-4).
- Previous and next arrows move the strip a week at a time.
- Date logic (week computation, day identity) lives in a testable model with unit tests; adds the unit test target.

## US-4 Save notes (Must)

As a user, I want what I write to be there when I reopen the app so that I never think about saving.

- Each day's note is stored in a local SQLite database via GRDB with a stable unique ID and portable text content.
- Autosave after a short idle period, on switching days and on window close and quit; after a force-quit at most the
  last moments of typing are lost.
- Relaunch restores every day's note. A failed save is reported visibly, never silently.
- Schema changes use versioned migrations.
- A note row is created on first edit; an untouched day stores nothing.

## US-5 Logical day boundary (Must)

As a user who works past midnight, I want to set when my day starts so that late-night writing belongs to the previous
day.

- A setting accepts a start time (e.g. 04:00), default 00:00. With 04:00, text written at 02:30 lands in the previous
  date's note.
- "Today" everywhere in the app uses the logical day.
- Changing the setting never moves existing notes, and an open note does not jump to another day at midnight.

## US-6 Breadcrumb and weekly notes (Must)

As a user, I want a Year / Month / Week / Day breadcrumb and a weekly note so that I can write at week level.

- The breadcrumb is always visible, shows the anchor date's year, month, week and day, and highlights the active
  level. Year and Month segments are shown and become clickable in US-7 and US-8.
- Clicking Week opens the weekly note and the strip shows adjacent weeks; clicking Day returns to the daily note of
  the same anchor date.
- Weeks spanning months or years (e.g. 29 Dec to 4 Jan) are labelled and stored consistently.

## US-7 Monthly notes (Must)

As a user, I want a monthly note so that I can write at month level.

- Clicking Month opens the monthly note and the strip shows months around the anchor date.
- Returning to Day or Week preserves the anchor date.

## US-8 Yearly notes (Must)

As a user, I want a yearly note so that I can write at year level.

- Clicking Year opens the yearly note and the strip shows adjacent years.
- From the yearly note, every other breadcrumb segment returns to the same anchor date's note.

## US-9 Markdown headings and emphasis (Must)

As a user, I want Markdown headings and emphasis styled as I type so that I can structure notes from the keyboard.

- `#` to `######` headings, `**bold**`, `*italic*` and `` `code` `` are styled while the syntax remains editable text.
- Undo and redo work across formatting; normal macOS selection and IME composition are unaffected.
- Content stored in the database stays plain Markdown text.

## US-10 Markdown lists (Must)

As a user, I want bullet and numbered lists that continue as I type so that lists are fast to write.

- `-`, `*` and `1.` start a list; Return continues it, and Return on an empty item ends it.
- Tab and Shift-Tab indent and outdent items; numbered lists renumber.

## US-11 Checkboxes (Must)

As a user, I want checkbox items I can toggle so that I can keep simple to-dos in a note.

- `- [ ]` renders a checkbox; clicking it toggles `[ ]` and `[x]` in the stored text.
- Return continues a checkbox list; these are editor checkboxes only, not tracked tasks.

## US-12 Meeting scratchpad (Must)

As a user in a meeting, I want a shortcut that opens a clean pad so that I can take notes without exposing my journal
when sharing my screen.

- A keyboard shortcut opens a window showing no journal content, breadcrumb or note list.
- The draft autosaves continuously; after a crash or relaunch an unfinished draft is offered for recovery.
- The pad is bound to the logical day on which it was opened.

## US-13 Finish or discard the scratchpad (Must)

As a user, I want to send the pad to my daily note or throw it away so that meeting notes live with my day only when I
choose.

- **Done** appends the Markdown to the daily note of the day the pad was opened, under an optional title heading.
  The pad closes and the draft is cleared only after the append is saved.
- **Discard** is explicit, asks for confirmation when the draft is non-empty, and appends nothing.

## US-14 See which days have notes (Should)

As a user, I want days with content marked in the strip so that I can spot where I wrote something.

- The weekday strip marks days whose notes contain text; the marks update as notes change.

## Out of Scope for MVP 0.1

Templates, Collections, tags, search, Quick Capture, native tasks beyond checkboxes, AI Insights, custom ranges,
undated notes, sync, other platforms, subscriptions. See [PRD.md](PRD.md) for phasing.
