# US-4b Save on Switch, Restore on Launch

Slice 2 of 3 for issue #4. Needs `2026-11-06-us4a-storage-layer.md`. Design:
`docs/superpowers/specs/2026-11-05-us4-save-notes-design.md`.

**Goal:** notes survive a quit. When the strip shows a week its notes are loaded, when you switch day or week the
pending text is saved, and a save that keeps failing crashes the app on purpose.

## Concept

`NotebookModel` only holds state and announces changes. A new collaborator, `NotePersistor`, listens to those
announcements and talks to the `NoteStore`: it loads the visible week and saves pending text. The model never calls a
store, a timer or a retry.

## Design

- **Observer.** The model has an optional observer (a small protocol) and calls it synchronously, with the data in the
  event: text was edited on a day, the visible week changed (first and last day). Synchronous matters: by the time
  `showNextWeek()` returns, the new week is loaded and the view renders the right notes.
- **Model is passive.** `model.loadNotes(_:)` replaces the notes of the visible week. The model has no dirty flag, no
  store and no flush; the `text` setter just updates state and notifies.
- **`NotePersistor` owns the policy.** It keeps the one pending edit (day and text). On the next day change, week
  change or an explicit `flush()` it writes the pending text, then clears it. On a week change it flushes, then loads
  the new week and hands it to the model. One class, two clearly separate responsibilities (load, save), so a
  `NoteLoader` can be split off later.
- **Decorator for failure policy.** `RetryingNoteStore` wraps any store: retry a failed call a few times (attempts and
  pause are plain configuration: a few tries and a short pause by default, no pause in tests), then call a give-up
  handler. The app's handler crashes (`fatalError`); tests pass a recording one. It covers loading too, so neither the
  model nor `NotePersistor` sees errors.
- **Composition root.** `makeDefault()` builds the store (path from `EVERLINE_DATABASE`, else the default location),
  wraps it, creates the model and `NotePersistor`, attaches the observer, and returns what `ContentView` needs. Tests
  build their own with a fake store.
- **E2E logic stays as is.** Only the e2e setup changes: each test launches with `EVERLINE_DATABASE` pointing at a
  fresh temporary file, so the real notebook is never touched and tests don't see each other's notes. No test body or
  assertion changes, and no e2e test is added.

## Data structures

- Model: `selected`, `today`, `notes` (`[Day: String]`, only the loaded week), `text` (view of `notes[selected]`).
- Observer events: `textEdited(day, text)` and `weekChanged(first, last)`. Events carry the data so the receiver never
  reads the model's current selection (that would have moved already).
- `NotePersistor`: the store, the model reference (weak), and `pending: (day, text)?`. A pending edit exists only
  after a real edit, so an untouched day is never saved and never gets a row.
- `FakeNoteStore` (tests only): a dictionary that records saves and can be told to fail.

## Data flow

- **Launch:** composition root creates everything; `NotePersistor` loads the current week into the model.
- **Typing:** editor binding sets `model.text`; the model updates state and emits `textEdited`; the persistor stores
  it as pending.
- **Switch day:** the model emits the selection change; the persistor flushes (empty text deletes the row).
- **Switch week:** flush pending, fetch the new week, `model.loadNotes`, in that order, before the call returns.
- **Failure:** retry, retry, give up, crash. No error UI.

## Work order

1. Observer surface and `loadNotes` on the model; model tests with no store.
2. `FakeNoteStore`, `NotePersistor` and its tests (events in, store calls out).
3. `RetryingNoteStore`.
4. Composition root with the `EVERLINE_DATABASE` override, and `ContentView` wiring.
5. E2E setup uses a temporary database; `CLAUDE.md` update.

## Testing

- **Model tests:** events fire with the right data; `loadNotes` replaces the week; no store involved.
- **Persistor tests (fake store):** pending saved on day change, week change and flush; untouched day never saved;
  clearing text saves empty; week change loads and fills the model before returning; a second edit replaces the first
  pending one. Persisting across a relaunch is covered by slice 1's store tests (reopening the file).
- **Decorator tests:** a transient failure is retried without giving up; the last failure calls the handler.
- **Existing component and e2e tests:** unchanged. The model's API and `ContentView` behave as before; the only e2e
  change is the setup (temporary database path).

## Risks

- Reentrancy: `loadNotes` is called from inside the model's own `showNextWeek`. A test pins the order and that the
  model ends in a consistent state.
- Ownership: the model holds the observer weakly and the persistor holds the model weakly; the composition root keeps
  both alive.
- Tests and e2e must never open the real notebook: component tests inject a store; e2e passes a temporary path.
- Retries block the main thread briefly, only when something is already wrong.
