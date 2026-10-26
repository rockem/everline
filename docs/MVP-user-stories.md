# Everline — MVP 0.1 User Stories

Scope and acceptance criteria live in [MVP.md](MVP.md). Product context lives in [PRD.md](PRD.md).

Priority: **Must** = required for MVP 0.1. **Should** = valuable, can slip if the schedule is tight.

## Epic 0: Walking Skeleton

The thinnest end-to-end slice: the app opens a note window, with no saving, and the whole delivery pipeline is in
place around it (tests, linting, build, publish). Every later story lands on top of this pipeline. Stories 0.1 to 0.5
are each small enough to finish in one sitting and should be done in order.

### US-0.1 Open a note window (Must)

As a user, I want to launch the app and see a window with an empty editable note so that there is a running app to
build on.

- Launching shows one window containing a native, editable text area.
- Typing works; nothing is saved, and the text is gone after quit. This is expected for the skeleton.
- No navigation, Markdown, database or settings yet.
- The app target is named Everline (replacing the template's `MyApp` and "Hello, world!").
- The deployment target is macOS 14.0.

### US-0.2 Run automated tests (Must)

As a developer, I want a test target and a one-command test run so that every later story can be built test-first.

- A unit test target exists, with one real test of a small piece of model code (not an empty placeholder).
- A UI test target exists with one smoke test: launch the app and confirm the editable note is present.
- `xcodebuild test` (wrapped in a script such as `scripts/test.sh`) runs both and fails on any failure.

### US-0.3 Lint the code and docs (Must)

As a developer, I want linting enforced so that style problems are caught before review.

- SwiftLint is configured (`.swiftlint.yml`) and passes on the skeleton.
- markdownlint passes on `docs/` using the existing `.markdownlint.json`.
- One command (such as `scripts/lint.sh`) runs both and fails on any violation.

### US-0.4 Build in CI (Must)

As a developer, I want every push and pull request built, tested and linted automatically so that main is always
green.

- A GitHub Actions workflow on a macOS runner runs lint, build and test using the same scripts as local runs.
- A failing step fails the check.
- Both Debug and Release configurations build, with compiler warnings treated as errors.

### US-0.5 Publish a build (Must)

As a developer, I want a tagged release to produce a downloadable app so that I can install the skeleton on my Mac
like a real user.

- Pushing a version tag (e.g. `v0.0.1`) runs a workflow that builds Release and attaches a zipped (or DMG) app to a
  GitHub Release.
- The marketing version comes from the tag (`v0.0.1` gives 0.0.1) and the build number from the CI run number.
- Code signing and notarization are deferred; an unsigned build is acceptable for now and the release notes say so.

Decisions for this epic:

- **Distribution:** GitHub Releases only for now. TestFlight and the Mac App Store are deferred, along with the paid
  Apple Developer account, signing and notarization they need.
- **Minimum macOS version:** macOS 14 (Sonoma). The project currently targets macOS 26.6.2, which is too high for
  real users, so US-0.1 lowers the deployment target to 14.0.
- **Versioning:** semantic versioning, `MAJOR.MINOR.PATCH`, from git tags. The skeleton ships as `0.0.1`, MVP 0.1
  as `0.1.0`, and `1.0.0` is reserved for the first public release. The build number is the CI run number.

Open decision: whether `scripts/` wrap `xcodebuild` directly or use a task runner such as `make` or `fastlane`.
Default is plain shell scripts.

## Epic 1: Time Navigation

Depends on Epic 0.

### US-1.1 Open on today (Must)

As a user, I want the app to open on today's daily note so that I can start writing immediately.

- Launch shows the daily note for the current **logical** day.
- The breadcrumb and strip reflect that day as the anchor date.

### US-1.2 See the full breadcrumb (Must)

As a user, I want the Year / Month / Week / Day breadcrumb always visible so that I always know where I am in time.

- All four segments are visible at every level, with the active one highlighted.
- Segment labels show the anchor date's actual year, month, week and day.

### US-1.3 Jump to any period from the breadcrumb (Must)

As a user, I want to click any breadcrumb segment so that I can open that period's own note.

- Clicking Year, Month, Week or Day opens the note for that period around the anchor date.
- Each period has its own independent content.

### US-1.4 Browse periods with the strip (Must)

As a user, I want a horizontal strip that matches the current level so that I can move to neighbouring periods.

- Day level: seven weekdays, with the selected day highlighted and Today distinguished.
- Week level: adjacent weeks. Month level: months. Year level: adjacent years.
- Selecting an item opens that period's note.

### US-1.5 Keep context when zooming out and in (Must)

As a user, I want to go from a yearly note back to a daily note without losing my place so that navigation feels
predictable.

- A single anchor date is retained across level changes.
- Returning to Day from Year shows the day I was on before.

### US-1.6 Navigate week and year boundaries correctly (Must)

As a user, I want weeks that cross months or years to behave correctly so that I never land on the wrong note.

- A week spanning 29 Dec to 4 Jan is handled consistently in the breadcrumb and strip.
- The week start day follows a single defined rule (see open questions in the PRD).

### US-1.7 See which days have notes (Should)

As a user, I want days with content marked in the strip so that I can spot where I wrote something.

## Epic 2: Writing

### US-2.1 Write in a native editor (Must)

As a user, I want a native Mac text editor so that typing, selection and input methods behave like any Mac app.

- Standard macOS selection, copy/paste, spell check and IME composition work.
- Undo and redo work across typing and formatting.

### US-2.2 Use basic Markdown (Must)

As a user, I want Markdown-style syntax so that I can structure notes quickly from the keyboard.

- Supported: headings, emphasis, bullet lists, numbered lists and checkboxes.
- Pressing Return in a list continues the list; checkboxes can be toggled.

### US-2.3 Never lose my writing (Must)

As a user, I want my notes saved automatically so that I never think about saving.

- Changes persist after a short idle period and on navigation, window close and quit.
- After a force-quit, at most the last moments of typing are lost.
- A failed save is reported visibly, never silently.

### US-2.4 Keep separate notes per period (Must)

As a user, I want the day, week, month and year to each have their own note so that I can write at the right level.

- Editing the weekly note does not change the daily note, and vice versa.
- A note is created lazily when first edited; empty periods are not stored.

## Epic 3: Logical Day

### US-3.1 Set when my day ends (Must)

As a user who works past midnight, I want to set the start-of-day time so that late-night writing belongs to the
previous day.

- A setting accepts a start time (e.g. 04:00).
- With 04:00, text written at 02:30 appears in the previous date's note.
- "Today" in the app, strip and scratchpad all use the logical day.

### US-3.2 Keep history stable (Must)

As a user, I want changing the setting not to move old notes so that my history stays intact.

- Existing notes keep their dates when the boundary changes.
- An already-open note does not jump to another day at midnight.

## Epic 4: Meeting Scratchpad

### US-4.1 Open a clean pad with a shortcut (Must)

As a user in a meeting, I want a shortcut that opens a fresh blank window so that I can take notes without exposing my
journal when sharing my screen.

- The window shows no journal content, breadcrumb or note list.
- The shortcut works from within the app, and is configurable if feasible (Should).

### US-4.2 Recover an unfinished pad (Must)

As a user, I want the scratchpad draft autosaved so that a crash or accidental close doesn't lose meeting notes.

- Drafts autosave continuously.
- After relaunch, an unfinished draft is offered for recovery.

### US-4.3 Send the pad to my daily note (Must)

As a user, I want to press Done to insert the pad into my daily note so that meeting notes live with my day.

- Done appends the Markdown to the daily note of the logical day on which the pad was opened.
- An optional title becomes a heading above the content.
- The pad closes and the draft is cleared only after the append is saved.

### US-4.4 Discard safely (Must)

As a user, I want to discard a pad deliberately so that throwaway notes don't clutter my day.

- Discard requires an explicit action and, for non-empty drafts, a confirmation.
- Discard appends nothing to any note.

## Epic 5: Storage and Reliability

### US-5.1 Store notes locally (Must)

As a user, I want my notes stored on my Mac in a reliable database so that they are private and work offline.

- Notes persist in a local SQLite database via GRDB with stable unique IDs.
- Content is stored as portable text.

### US-5.2 Survive restarts and upgrades (Must)

As a user, I want my data intact after restarts and app updates so that I can trust the app with daily work.

- Schema changes use versioned migrations.
- Data persists across quit, force-quit and relaunch.

## Out of Scope for MVP 0.1

Templates, Collections, tags, search, Quick Capture, native tasks beyond checkboxes, AI Insights, custom ranges,
undated notes, sync, other platforms, subscriptions. See [PRD.md](PRD.md) for phasing.
