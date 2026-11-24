# US-4: Save Notes — Design

Issue: [#4](https://github.com/rockem/everline/issues/4). Builds on US-3 (daily notes, weekday strip).

## Intent

Whatever the user writes must be there when they reopen the app, without them ever thinking about saving. Today every
note lives in `NotebookModel` memory and is lost on quit. This story makes notes durable in a local SQLite database.

The storage must not box in what comes next: notes for weeks, months and years, notes for arbitrary date ranges, notes
tied to no period at all, and later sync between devices. None of those are built now. The schema just must not need
a rewrite to hold them.

## Goals

- Each day's note is stored locally via GRDB (SQLite) and restored on relaunch.
- Autosave never loses more than 5 seconds of typing, even on a force-quit.
- Schema changes go through versioned GRDB migrations from the first version.
- A note row exists only after the first edit that leaves non-empty text. An untouched day stores nothing.

## Non-goals

- Creating or reading week, month, year, range or undated notes. Only day notes are written and read. The schema
  merely has room for the rest. (`docs/MVP.md` also lists ranges, undated notes and sync as out of the MVP.)
- Sync, export, encryption, search.
- Any UI for save status or save errors (see Failure handling).
- A recovery file or any second copy of the text.

## Anti-goals

- Silent data loss: a failed save must never leave the user believing text is stored when it is not.
- Blocking the typing path: saving must not make typing stutter.
- Keeping stale text: a note cleared to empty must not come back after relaunch.

## Storage

GRDB, one SQLite file in the app's Application Support directory, same on macOS and iOS (builder's call on the exact
folder and file name). GRDB is added as a Swift package dependency of the app target.

GRDB is used as a thin SQLite toolkit, not an ORM (the user dislikes ORMs). The schema and queries are plain SQL; the
note is a plain struct that maps to a row. No query-builder DSL and no objects that track changes. (Decided.)

Table `notes`:

| Column | Type | Meaning |
| --- | --- | --- |
| `id` | UUID (text) | primary key, generated when the note row is first created, never changes |
| `text` | text | the note content, plain text, stored as typed |
| `created_at`, `updated_at` | timestamps | `updated_at` is set on every save (needed later for sync) |
| `scope` | text, nullable | `day`, `week`, `month` or `year`; empty for range and undated notes |
| `start_date`, `end_date` | text, nullable | inclusive `YYYY-MM-DD`; both set or both empty |

Rules:

- A day note has `scope = 'day'` and `start_date = end_date = the day`.
- `(scope, start_date, end_date)` is unique when `scope` is set, so a period cannot have two notes.
- Notes with an empty `scope` (arbitrary ranges, undated) are exempt, so several may share the same dates.
- `start_date` and `end_date` are both set or both empty (a database check).
- The uniqueness is a partial unique index (only where `scope` is not null), created in a migration (my call).
- The database does not restrict the values of `scope`; the app validates them, because the set may grow and a
  database rule would force a migration each time. (Decided.)
- A composite index on `(start_date, end_date)` supports "which notes cover this date" queries later.
- Clearing a note's text to empty deletes its row, matching how the in-memory model already drops empty strings.
- There is no `identifier` column (for example `2026-W44`). It would only matter for week notes surviving a change of
  the first-weekday setting, which is undecided; add it with a migration when week notes are built. (Decided.)

Looking up "the note for a day" is an exact match on `(scope, start_date, end_date)`.

## Migrations

Schema changes use GRDB's `DatabaseMigrator` from the first version. Each change is a named step; applied steps are
recorded by GRDB and run once, in order, on every launch before the database is used. `v1` creates `notes` as above.
A shipped step is never edited; later changes are new steps. `eraseDatabaseOnSchemaChange` stays off. A migration that
throws crashes the app, like a failed save, and runs in a transaction so the database is left unchanged. Tests run the
migrator on a fresh temporary SQLite file and assert the schema and rules; from `v2` on, a test migrates a `v1`
database that holds data.

## Saving

- A save is scheduled when the text changes. It runs once the user has paused for about 2 seconds, and never later
  than 5 seconds after the first unsaved change, so continuous typing still saves. The 5 seconds is the user's stated
  tolerance; the 2 seconds is a proposal (my call).
- Pending text is saved immediately when the user switches day or week, closes the window, or quits the app.
- The model holds only the notes of the days the strip shows. When the strip shows a new week (launch, previous or
  next week) it loads that week in one query for the notes whose dates overlap the week
  (`start_date <= last_day AND end_date >= first_day`, served by the `(start_date, end_date)` index) and keeps them
  while the user stays on the week. Selecting a day inside the strip reads nothing. Relaunch therefore restores each
  day's note as soon as the user can see it; days with no row show empty. For US-4 only `scope = 'day'` rows are read
  into the model's `[Day: String]`, so the store offers something like `notes(scope:from:to:)`; generalizing the key to
  other kinds of notes belongs to the story that adds them. (The user's decision.)
- The flush on day switch, window close and quit is synchronous: it is one small write, and the app must not exit or
  move on before the text is stored. On macOS the quit flush runs in the app's terminate path. iOS has no window close
  or quit, so the flush runs when the scene leaves the foreground (`scenePhase` becomes inactive or background), the
  point where iOS may suspend or kill the app (my call).
- Only truly empty text deletes the row. Whitespace-only text is stored as typed (my call).

## Failure handling

A failed save is retried a few times. If it still fails, the app crashes deliberately. There is no error UI, no
dialog, and no recovery file. This was the user's explicit choice over a retry-then-alert design, accepting that the
unsaved text is lost in that case. This loosens the issue's wording "reported visibly, never silently": the crash is
the report. The issue's acceptance criteria should be updated to say so.

- The same rule applies to a failure during a day-switch, close, quit or background flush: retry, then crash.
- Retries are quick (a total of roughly a second or two), so a retrying save stays inside the 5-second bound. The crash
  itself may land later than 5 seconds after the first unsaved edit; the bound is about typing lost to a force-quit,
  not a promise that a failing save fails fast (my call).
- The exact retry count and spacing are left to the builder.

## Constraints

- macOS 14 and iOS 17 minimum; one multiplatform app target; GRDB must work on both.
- The Xcode project is hand-edited for packages and targets (synchronized folder groups handle new source files).
  `Package.resolved` is tracked.
- `NotebookModel` stays unit-testable with an injected `Calendar`, and the model and its callers keep working with
  a hand-written fake store (no database, no mocking framework) in tests. The store's own tests (migrations,
  constraints, saving, loading, reopening) run against a real SQLite file created in a temporary folder per test and
  deleted afterwards; no in-memory database, so tests and production behave the same.
- Function order and test layering follow `CLAUDE.md` (component tests in `everlineTests`, e2e only for whole flows).
- Tests never touch the user's real notebook. Model and UI tests inject the fake store; store tests use their own
  temporary file. The e2e suite needs a launch flag or environment variable (like `EVERLINE_TODAY`) that points the
  app at a temporary database file; how it is named is the builder's call.

## Left to the builder

- How `NotebookModel` talks to the database (protocol, repository, or injected closure), as long as the model remains
  testable without disk access.
- Threading and how the debounce timer is implemented.
- Retry count and spacing; the exact database file location.
- Test design for autosave timing, switching days, quit, relaunch, and the crash path.
