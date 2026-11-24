import Foundation

/// Decides when notes are loaded and saved. It listens to the model, keeps the one pending edit, writes it when the
/// selection or the range moves, after a pause in typing (or at a deadline while typing goes on), or when the app
/// is leaving, and loads the notes of a range when the model enters it (attaching to the model
/// included). Errors are the store's business (see `RetryingNoteStore`), so a failed call simply leaves the model as
/// it was.
final class NotePersistor: NoteRangeObserver {
    private let store: NoteStore
    private weak var model: NoteRangeModel?
    private var pending: (day: Day, text: String)?
    private let scheduler: Scheduler
    private let timing: AutosaveTiming
    private lazy var autosave = AutosaveTimer(timing: timing, scheduler: scheduler) { [weak self] in
        self?.flush()
    }

    init(
        store: NoteStore,
        model: NoteRangeModel,
        scheduler: Scheduler = MainQueueScheduler(),
        lifecycle: AppLifecycle = AppLifecycle(),
        timing: AutosaveTiming = .standard
    ) {
        self.store = store
        self.model = model
        self.scheduler = scheduler
        self.timing = timing
        lifecycle.onLeaving = { [weak self] in self?.flush() }
    }

    private func load(_ first: Day, _ last: Day) {
        guard let notes = try? store.notes(scope: .day, from: first, to: last) else { return }
        model?.loadNotes(notes)
    }

    func textEdited(day: Day, text: String) {
        pending = (day, text)
        autosave.edited()
    }

    func selectionChanged(to _: Day) {
        flush()
    }

    /// Writes the pending edit, if any.
    private func flush() {
        autosave.stop()
        guard let edit = pending else { return }
        pending = nil
        try? store.save(edit.text, for: edit.day)
    }

    /// The range can move without the selection, so the pending edit is written before loading: the selected day may
    /// be inside the new range, and the store must hold its latest text.
    func rangeChanged(from first: Day, to last: Day) {
        flush()
        load(first, last)
    }
}
