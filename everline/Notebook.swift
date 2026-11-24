import Foundation

/// The composition root: a model, the persistor that keeps it in step with a store, and the lifetime of both (the
/// model only holds its observer weakly).
final class Notebook {
    /// Reports the app leaving to the persistor. The app tells it when a scene goes to the background (iOS).
    let lifecycle: AppLifecycle
    private let persistor: NotePersistor

    init(
        store: NoteStore,
        today: Day,
        calendar: DayCalendar,
        scheduler: Scheduler = MainQueueScheduler(),
        lifecycle: AppLifecycle = AppLifecycle(),
        timing: AutosaveTiming = .standard
    ) {
        model = NoteRangeModel(today: today, calendar: calendar)
        self.lifecycle = lifecycle
        persistor = NotePersistor(
            store: store,
            model: model,
            scheduler: scheduler,
            lifecycle: lifecycle,
            timing: timing
        )
        model.observer = persistor
    }
}

extension Notebook {
    /// The real notebook: the SQLite file from `NotebookDatabase.defaultLocation()` (`EVERLINE_DIR` overrides the
    /// folder) behind the retry-then-crash policy. `EVERLINE_TODAY=YYYY-MM-DD` overrides today so UI tests are
    /// deterministic.
    static func makeDefault() -> Notebook {
        let store: NoteStore
        do {
            let location = try NotebookDatabase.defaultLocation()
            store = try RetryingNoteStore(SQLiteNoteStore(database: NotebookDatabase(path: location)))
        } catch {
            fatalError("Cannot open the notebook: \(error)")
        }
        let calendar = DayCalendar(.current)
        let override = ProcessInfo.processInfo.environment["EVERLINE_TODAY"]
        let today = override.flatMap { Day(iso: $0) } ?? calendar.day(of: Date())
        return Notebook(store: store, today: today, calendar: calendar)
    }
}
