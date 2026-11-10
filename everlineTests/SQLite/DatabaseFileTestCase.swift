import GRDB
import XCTest
@testable import everline

/// Base for tests that need a real SQLite file: a fresh temporary folder per test, removed afterwards.
@MainActor
class DatabaseFileTestCase: XCTestCase {
    private var folder: URL!

    var path: URL {
        folder.appendingPathComponent("notebook.sqlite")
    }

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("everline-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: folder)
    }

    func openDatabase() throws -> NotebookDatabase {
        try NotebookDatabase(path: path)
    }

    /// The first column of every row the query returns, as text.
    func strings(_ sql: String) throws -> [String] {
        try openDatabase().queue.read { try String.fetchAll($0, sql: sql) }
    }

    func count(_ sql: String) throws -> Int {
        try openDatabase().queue.read { try Int.fetchOne($0, sql: sql) } ?? 0
    }

    /// Inserts a row straight into the table, bypassing the store.
    func insertRow(scope: String?, start: String?, end: String?) throws {
        func literal(_ value: String?) -> String {
            value.map { "'\($0)'" } ?? "NULL"
        }
        try openDatabase().queue.write {
            try $0.execute(sql: """
                INSERT INTO notes (id, text, created_at, updated_at, scope, start_date, end_date)
                VALUES ('\(UUID().uuidString)', 't', '2026-01-01 00:00:00', '2026-01-01 00:00:00',
                        \(literal(scope)), \(literal(start)), \(literal(end)))
                """)
        }
    }
}
