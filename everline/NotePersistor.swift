import Foundation

/// Decides when notes are loaded and saved. It listens to the model, keeps the edits not yet saved, writes them when
/// the selection or the range moves, after a pause in typing (or at a deadline while typing goes on), or when the app
/// is leaving, and loads the notes of a range when the model enters it (attaching to the model included). How a
/// failing store is handled is the store's business (see `RetryingNoteStore`), but an edit whose save failed is never
/// dropped: it stays unsaved, is tried again after the next pause, and shows through every load until it is saved.
final class NotePersistor: NoteRangeObserver {
    private let store: NoteStore
    private weak var model: NoteRangeModel?
    private var unsaved: [Day: String] = [:]
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
        guard var notes = try? store.notes(scope: .day, from: first, to: last) else { return }
        for (day, text) in unsaved where first <= day && day <= last {
            notes[day] = text.isEmpty ? nil : text
        }
        model?.loadNotes(notes)
    }

    func textEdited(day: Day, text: String) {
        unsaved[day] = text
        autosave.edited()
    }

    func selectionChanged(to _: Day) {
        flush()
    }

    /// Writes the unsaved edits. Those that fail stay unsaved and are tried again after the next pause.
    private func flush() {
        autosave.stop()
        for (day, text) in unsaved.sorted(by: { $0.key < $1.key }) {
            guard (try? store.save(text, for: day)) != nil else { continue }
            unsaved[day] = nil
        }
        if !unsaved.isEmpty {
            autosave.edited()
        }
    }

    /// The range can move without the selection, so unsaved edits are written before loading: the selected day may
    /// be inside the new range, and the store must hold its latest text.
    func rangeChanged(from first: Day, to last: Day) {
        flush()
        load(first, last)
    }
}
