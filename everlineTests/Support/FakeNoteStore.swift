@testable import everline

/// An in-memory `NoteStore` that records what it is asked and can be told to fail.
final class FakeNoteStore: NoteStore {
    struct Failure: Error {}

    enum Call: Equatable {
        case load(Day, Day)
        case save(Day, String)
    }

    var notes: [Day: String] = [:]
    var calls: [Call] = []
    var failuresLeft = 0

    var saves: [Call] {
        calls.filter { if case .save = $0 { true } else { false } }
    }

    func notes(scope _: Scope, from first: Day, to last: Day) throws -> [Day: String] {
        calls.append(.load(first, last))
        try failIfTold()
        return notes.filter { first <= $0.key && $0.key <= last }
    }

    func save(_ text: String, for day: Day) throws {
        calls.append(.save(day, text))
        try failIfTold()
        notes[day] = text.isEmpty ? nil : text
    }

    private func failIfTold() throws {
        guard failuresLeft > 0 else { return }
        failuresLeft -= 1
        throw Failure()
    }
}
