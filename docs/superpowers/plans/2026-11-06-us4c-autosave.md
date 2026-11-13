# US-4c Autosave and Exit Flushes

Slice 3 of 3 for issue #4. Needs `2026-11-06-us4b-save-and-restore.md`. Design:
`docs/superpowers/specs/2026-11-05-us4-save-notes-design.md`.

**Goal:** typing is saved automatically, so a force-quit loses at most 5 seconds, and leaving the app always flushes.

## Concept

Slice 2 saves when you switch day or week. This slice gives `NotePersistor` two more reasons to flush: a timer while
you type, and app lifecycle events (window close, quit, iOS backgrounding). The model is untouched.

## Design

- **Debounce with a deadline, inside `NotePersistor`.** An `AutosaveTimer` holds two timers. An *idle* timer (2
  seconds) restarts on every edit. A *deadline* timer (5 seconds) starts at the first edit after a save and is not
  restarted. Whichever fires first calls `flush()`, which cancels both. Pausing saves after 2 seconds; continuous
  typing still saves every 5.
- **Injected scheduler.** The timer uses a small `Scheduler` interface (run work after N seconds, return a cancellable).
  Production uses the main queue; tests use a manual scheduler that advances time by hand, so no test waits real
  seconds.
- **Lifecycle hooks call the persistor directly.** `ContentView` calls `persistor.flush()` on macOS when the app is
  about to terminate and when the window closes (notifications), and on iOS when the scene leaves the foreground
  (`scenePhase`). The flush is synchronous.

## Data structures

- `Scheduler` and a cancellable handle (small protocols), plus the manual scheduler for tests.
- `AutosaveTimer`: idle handle, deadline handle, and the callback into `NotePersistor`. Armed only by `textEdited`
  events, so visiting a day never starts it.
- `AutosaveTiming`: `idle` and `deadline` as plain configuration, defaulting to 2 and 5 seconds (5 is the user's
  tolerance). The composition root passes it to `NotePersistor`; tests use tiny values (for example 0.05 and 0.15
  seconds) wherever a real scheduler is involved, so nothing waits real seconds. Not user-facing settings.

## Data flow

- **Edit:** `textEdited` arrives, pending is replaced, the timer restarts idle and starts the deadline if not running.
- **Timer fires:** `flush()` writes the pending edit, clears it, cancels both timers.
- **Switch day/week, close, quit, background:** `flush()` immediately.
- **Failure on any flush:** the slice-2 retry-then-crash policy applies unchanged.

## Work order

1. `Scheduler`, manual test scheduler, `AutosaveTimer` with tests.
2. Connect the timer to `NotePersistor` (arm on edit, cancel on flush).
3. Lifecycle flush hooks in `ContentView` with their component test; iOS compile check.
4. `CLAUDE.md` update.

## Testing

- **Timer tests (manual scheduler, configured timing):** no edit means no fire; a pause fires after the idle time;
  continuous edits fire at the deadline; a flush cancels both; an edit after a flush starts a new cycle.
- **Persistor tests (fake store and manual scheduler):** an edit then advancing time saves; no edit saves nothing.
- **New component test (hosted `ContentView`, fake persistor):** posting the app-terminate notification calls `flush()`;
  closing the hosted window calls `flush()`. This pins the macOS lifecycle wiring. (`ContentView` takes the persistor
  as an injectable dependency, defaulting to the real one.)
- **Existing component and e2e tests:** unchanged.

## Risks

- The iOS `scenePhase` hook is only compile-checked and has no automated test; check backgrounding manually once.
- Slice 2's temporary database in the e2e setup must be in place, so e2e never touches the real notebook.
