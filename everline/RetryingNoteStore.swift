import Foundation

/// Wraps a store with the failure policy: a failed call is retried a few times, and when the last attempt fails the
/// give-up handler runs (the app's crashes on purpose) before the error is rethrown. Callers never see transient
/// errors.
final class RetryingNoteStore: NoteStore {
    private let store: NoteStore
    private let attempts: Int
    private let pause: TimeInterval
    private let onGiveUp: (Error) -> Void

    init(
        _ store: NoteStore,
        attempts: Int = 3,
        pause: TimeInterval = 0.2,
        onGiveUp: @escaping (Error) -> Void = { fatalError("Cannot read or write the notebook: \($0)") }
    ) {
        self.store = store
        self.attempts = attempts
        self.pause = pause
        self.onGiveUp = onGiveUp
    }

    func notes(scope: Scope, from first: Day, to last: Day) throws -> [Day: String] {
        try retrying { try store.notes(scope: scope, from: first, to: last) }
    }

    func save(_ text: String, for day: Day) throws {
        try retrying { try store.save(text, for: day) }
    }

    private func retrying<T>(_ call: () throws -> T) throws -> T {
        var attempt = 1
        while true {
            do {
                return try call()
            } catch {
                guard attempt < attempts else {
                    onGiveUp(error)
                    throw error
                }
                attempt += 1
                Thread.sleep(forTimeInterval: pause)
            }
        }
    }
}
