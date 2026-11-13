import Foundation
import GRDB

/// Notes in the notebook database. GRDB is used as a thin toolkit: the queries are plain SQL.
final class SQLiteNoteStore: NoteStore {
    private let queue: DatabaseQueue

    init(database: NotebookDatabase) {
        queue = database.queue
    }

    func notes(scope: Scope, from first: Day, to last: Day) throws -> [Day: String] {
        try queue.read { database in
            let rows = try Row.fetchAll(database, sql: """
                SELECT start_date, text FROM notes
                WHERE scope = ? AND start_date <= ? AND end_date >= ?
                """, arguments: [scope.rawValue, last.id, first.id])
            var notes: [Day: String] = [:]
            for row in rows {
                let start: String = row["start_date"]
                if let day = Day(iso: start) {
                    notes[day] = row["text"]
                }
            }
            return notes
        }
    }

    func save(_ text: String, for day: Day) throws {
        try queue.write { database in
            if text.isEmpty {
                try Self.delete(day, in: database)
            } else {
                try Self.upsert(text, for: day, in: database)
            }
        }
    }

    private static func delete(_ day: Day, in database: Database) throws {
        try database.execute(sql: "DELETE FROM notes WHERE scope = ? AND start_date = ? AND end_date = ?",
                       arguments: [Scope.day.rawValue, day.id, day.id])
    }

    /// Inserts the day's note, or replaces its text and `updated_at` when one exists (`id` and `created_at` stay).
    private static func upsert(_ text: String, for day: Day, in database: Database) throws {
        let now = Date()
        try database.execute(sql: """
            INSERT INTO notes (id, text, created_at, updated_at, scope, start_date, end_date)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT (scope, start_date, end_date) WHERE scope IS NOT NULL
            DO UPDATE SET text = excluded.text, updated_at = excluded.updated_at
            """, arguments: [UUID().uuidString, text, now, now, Scope.day.rawValue, day.id, day.id])
    }
}
