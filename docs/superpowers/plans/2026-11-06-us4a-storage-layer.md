# US-4a Storage Layer

Slice 1 of 3 for issue #4. Design: `docs/superpowers/specs/2026-11-05-us4-save-notes-design.md`. Next:
`2026-11-06-us4b-save-and-restore.md`, then `2026-11-06-us4c-autosave.md`.

**Goal:** a tested SQLite store that saves day notes and loads notes by scope. Nothing in the app uses it yet.

## Concept

The app talks to notes through a small `NoteStore` interface. The real implementation, `SQLiteNoteStore`, keeps them in
one local SQLite file using GRDB as a thin toolkit: plain SQL, no ORM. Everything above the store (model, UI, tests)
depends only on the interface, so it can run against a fake.

## Design

- **Technology stays in one folder.** Everything that knows SQLite or GRDB lives in `everline/SQLite/`; the rest of
  the app sees only `NoteStore`.
- **Repository pattern.** `NoteStore` is the seam; `SQLiteNoteStore` holds only the queries.
- **Database and migrations are separate from the store.** `NotebookDatabase` opens the file, runs the migrations and
  exposes the connection (and the default location). `Migrations` is the schema history: one SQL file per step in
  `SQLite/Migrations/`, named `NNNN-description.sql`, loaded in order from the bundle. The store is built from an
  already migrated database.
- **Versioned migrations.** GRDB's `DatabaseMigrator` runs named steps once, in order, when the database opens. First
  step: `0001-create-notes`. Shipped steps are never edited.
- **Day lookups go through `Day`.** Dates are stored as `YYYY-MM-DD` text, the same format as `Day.id`. `Day` gets a
  calendar-free `init?(iso:)` for parsing rows (it replaces `DayCalendar.day(iso:)`).
- **One connection, one serial queue** (`DatabaseQueue`). Writes are tiny, so a pool buys nothing.

## Data structures

`NoteStore` has two operations:

- `notes(scope:from:to:)` returns `[Day: String]`: the notes of one explicit `Scope` that overlap a date range, keyed
  by the day each period starts on. For `day` that is the day itself; for `week` it will be the week's first day.
  `Scope` is a small enum (`day`, `week`, `month`, `year`) stored as its text name. The key is unique because the
  database allows one note per scope and start day. `scope` is nullable in the table (range and undated notes), but
  those are never returned by this fetch: they may share start days, so they need a different query and return type
  (a list) in the story that adds them.
- `save(_:for:)` stores a day's text; empty text deletes the row. Saving other scopes needs a period's end date, so
  it waits for the story that adds them.

Table `notes`:

| Column | Notes |
| --- | --- |
| `id` | UUID as text, created with the row, never changes |
| `text` | plain text, stored as typed (whitespace-only is kept) |
| `created_at`, `updated_at` | timestamps; `updated_at` changes on every save |
| `scope` | nullable; `day` for now, later week, month, year |
| `start_date`, `end_date` | nullable, inclusive; both set or both null |

Rules enforced by the database: `(scope, start_date, end_date)` is unique where `scope` is set; the two dates are paired;
an index on `(start_date, end_date)` serves range queries. Range and undated notes may repeat dates. Scope values are
validated by the app, not the database.

## Data flow

- **Save:** non-empty text becomes an upsert on the unique key (new row gets a fresh UUID, existing row keeps its id
  and gets a new `updated_at`). Empty text deletes the row, so an untouched day never has one.
- **Load:** one range query for rows of the requested scope that overlap the range, keyed by `start_date` as a `Day`. Rows
  with an unparseable date are skipped. The app asks for `day` only, for now.
- **Open:** create the folder and file if missing, run pending migrations, then serve calls. A path that cannot hold a
  database throws.
- **Location:** `Everline/notebook.sqlite` inside Application Support, on both platforms.

## Work order

1. `Day(iso:)` without a calendar.
2. Add GRDB (exact version, app and test targets), the interface, open and migrate.
3. Save and load.
4. Default location, and a `CLAUDE.md` note.

## Testing

Store tests use a real SQLite file in a temporary folder per test. They cover the schema rules (by inserting rows
through a second connection), save and load round trips, a fetch returning only the requested scope (not unscoped
rows), reopening the file, upsert keeping one row and one id, and failure to open. No other layer is
touched. The iOS compile check confirms GRDB builds there.

## Risks

- The upsert must name the partial unique index as its conflict target; a wrong target errors or duplicates rows. The
  save tests catch it.
- A new third-party dependency (GRDB) in the app and test targets. Schema tests use GRDB directly for their
  assertions and raw inserts; linking it into the hosted test bundle showed no duplicate-class problems.
