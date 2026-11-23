# US-4b Save on Switch, Restore on Launch

Slice 2 of 3 for issue #4. Needs `2026-11-06-us4a-storage-layer.md`. Design:
`docs/superpowers/specs/2026-11-05-us4-save-notes-design.md`.

**Goal:** notes survive a quit. When a range is selected its notes are loaded, when you switch day or range the pending
text is saved, and a save that keeps failing crashes the app on purpose.

## Concept

`NotebookModel` is renamed `NoteRangeModel`. It only holds state (a selected day, a range that moves independently of
it, and the notes of that range plus the selected day) and announces changes. It knows nothing about screens, strips or
views. A new collaborator, `NotePersistor`, listens to those announcements and talks to the `NoteStore`: it loads the
selected range and saves pending text. The model never calls a store, a timer or a retry.

## Design

- **Rename.** `NotebookModel` becomes `NoteRangeModel`, `showNextWeek()` becomes `nextRange()` and
  `showPreviousWeek()` becomes `previousRange()`. Both move the range by one range (7 days today) and leave the
  selection alone: the user selects another day explicitly. The rename is mechanical (model, its tests, `ContentView`,
  `CLAUDE.md`) and lands first, before any behavior change.
- **Observer.** The model has an optional observer (a small protocol) and calls it synchronously, with the data in the
  event: text was edited on a day, the selection moved to a day, the range changed (first and last day). Synchronous
  matters: by the time `nextRange()` returns, the new range is loaded into the model. Attaching an observer reports
  the current range too, so the first load needs no separate call.
- **Selection and range are separate.** The model keeps the selected day and a range anchor (a day of the range;
  today the range is that day's week). `nextRange()` and `previousRange()` move the anchor by 7 days and keep the
  selection, so the selected day may be outside the range (nothing is highlighted, the editor keeps its note).
  `select(_:)` sets the selection and then moves the anchor to that day. Both paths end in one private
  `moveRange(around:)` that emits `rangeChanged(from, to)` only when the range actually differs, so any future jump
  across ranges (today, a date picker) also loads. The event names only a range, so widening what is loaded later
  (month and year notes) needs no protocol change.
- **Model is passive.** `model.loadNotes(_:)` replaces the notes of the current range and keeps the selected day's own
  text when that day is outside it. The model has no dirty flag, no store and no flush; the `text` setter just updates
  state and notifies.
- **`NotePersistor` owns the policy.** It keeps the one pending edit (day and text). On a selection change or a
  range change it writes the pending text, then clears it. On a range change it then loads the new range and hands it
  to the model; the write comes first because the selected day may lie inside the new range and the store must hold
  its latest text. One class, two clearly separate responsibilities (load, save), so a `NoteLoader` can be split off
  later.
- **Decorator for failure policy.** `RetryingNoteStore` wraps any store: retry a failed call a few times (attempts and
  pause are plain configuration: a few tries and a short pause by default, no pause in tests), then call a give-up
  handler. The app's handler crashes (`fatalError`); tests pass a recording one. It covers loading too, so neither the
  model nor `NotePersistor` sees errors.
- **Composition root.** `Notebook` creates the model and `NotePersistor` around a given store, attaches the observer,
  keeps both alive (attaching the observer loads the first range). `Notebook.makeDefault()` builds the SQLite store
  (folder from
  `EVERLINE_DIR`, else the default location), wraps it in `RetryingNoteStore` and is held by `MyApp`; `ContentView`
  keeps taking a model. Tests build a `Notebook` with a fake store.
- **E2E logic stays as is.** Only the e2e setup changes: each test launches with `EVERLINE_DIR` set to a fresh
  relative folder name (the sandboxed app resolves it inside its temporary directory), so the real notebook is never
  touched and tests don't see each other's notes. No test body or assertion changes, and no e2e test is added.

## Data structures

- Model: `selected`, `rangeAnchor`, `today`, `notes` (`[Day: String]`, the current range plus the selected day), `text`
  (the note of `notes[selected]`).
- Observer events: `textEdited(day, text)`, `selectionChanged(to)` and `rangeChanged(from, to)`. Events carry the data
  so the receiver never reads the model's current selection (that would have moved already).
- `NotePersistor`: the store, the model reference (weak), and `pending: (day, text)?`. A pending edit exists only
  after a real edit, so an untouched day is never saved and never gets a row.
- `FakeNoteStore` (tests only): a dictionary that records saves and can be told to fail.

## Data flow

- **Launch:** composition root creates everything; attaching the persistor makes the model report its range and
  `NotePersistor` loads it.
- **Typing:** editor binding sets `model.text`; the model updates state and emits `textEdited`; the persistor stores
  it as pending.
- **Switch day:** the model emits the selection change; the persistor flushes (empty text deletes the row).
- **Switch range:** the selection stays; the range change flushes pending, fetches the new range and calls
  `model.loadNotes`, in that order, before the call returns.
- **Failure:** retry, retry, give up, crash. No error UI.

## Work order

1. Rename `NotebookModel` to `NoteRangeModel` and the navigation methods; existing tests pass unchanged apart from
   names.
2. Observer surface and `loadNotes` on the model; model tests with no store.
3. `FakeNoteStore`, `NotePersistor` and its tests (events in, store calls out).
4. `RetryingNoteStore`.
5. `Notebook` composition root with the `EVERLINE_DIR` override, and `MyApp` wiring.
6. E2E setup uses a temporary database; `CLAUDE.md` update.

## Testing

- **Model tests:** `nextRange()` moves the range and not the selection; `rangeChanged` fires when the range moves and
  when a selection leaves it, not within a range; events fire with the right data; `loadNotes` replaces the range but
  keeps an outside selected day's text; no store involved.
- **Persistor tests (fake store):** pending saved on selection change and range change; untouched day never saved; a
  saved edit is not saved again; a range change loads the new range before returning and the selected day keeps its
  text; a second edit replaces the first pending one. Persisting across a relaunch is covered by slice 1's store tests
  (reopening the file).
- **Decorator tests:** a transient failure is retried without giving up; the last failure calls the handler.
- **Existing component and e2e tests:** unchanged apart from the rename, the e2e setup (temporary database path) and
  the next/previous week assertions, which now expect the selection to stay and nothing to be highlighted.

## Risks

- Selecting a day within the same range must not emit `rangeChanged` (no reload, no flush); a test pins it.
- Reentrancy: the persistor calls `loadNotes` from inside the model's own `moveRange(around:)`. A test pins that the
  model ends consistent (same selection, new range), emits one event per change, and that the persistor never reads the
  model's state mid-change.
- Ownership: the model holds the observer weakly and the persistor holds the model weakly; the composition root keeps
  both alive.
- Tests and e2e must never open the real notebook: component tests inject a store; the hosted app gets `EVERLINE_DIR`
  from the shared scheme's test action; e2e passes its own relative folder name.
- Retries block the main thread briefly, only when something is already wrong.
