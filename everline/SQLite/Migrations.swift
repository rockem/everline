import Foundation
import GRDB

/// The schema history: one SQL file per step in `Migrations/`, named `NNNN-description.sql`. Each step runs once, in
/// order, on every database that has not seen it yet. A step that has shipped is never edited; a change to the schema
/// is a new file with the next number.
enum Migrations {
    struct File {
        let name: String
        let sql: String
    }

    /// Brings the database up to date: runs every step it has not seen yet.
    static func migrate(_ queue: DatabaseQueue) throws {
        try createMigrator().migrate(queue)
    }

    private static func createMigrator() throws -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        for file in try files() {
            migrator.registerMigration(file.name) { database in
                try database.execute(sql: file.sql)
            }
        }
        return migrator
    }

    /// The bundled migration files in numeric order.
    static func files() throws -> [File] {
        let bundle = Bundle(for: NotebookDatabase.self)
        let urls = bundle.urls(forResourcesWithExtension: "sql", subdirectory: nil) ?? []
        return try urls
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { try File(name: $0.deletingPathExtension().lastPathComponent,
                            sql: String(contentsOf: $0, encoding: .utf8)) }
    }
}
