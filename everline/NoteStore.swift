import Foundation

/// The kind of period a note belongs to. Notes with no scope (arbitrary ranges, undated) have none of these.
enum Scope: String {
    case day, week, month, year
}

/// Where notes live. The app only needs day notes for now.
protocol NoteStore {
    /// The notes of one scope that overlap `first...last`, keyed by the day each period starts on.
    func notes(scope: Scope, from first: Day, to last: Day) throws -> [Day: String]

    /// Stores a day's text. Empty text deletes the note, so an untouched day never has a row.
    func save(_ text: String, for day: Day) throws
}
