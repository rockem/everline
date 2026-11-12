import Foundation
import GRDB

/// The notebook's SQLite file: opens it and brings its schema up to date before anyone uses it.
final class NotebookDatabase {
    let queue: DatabaseQueue

    init(path: URL) throws {
        queue = try DatabaseQueue(path: path.path)
        try Migrations.migrate(queue)
    }

    /// `Everline/notebook.sqlite` inside the user's Application Support folder, which is created when missing.
    /// `EVERLINE_DIR` replaces the Application Support folder, so tests and UI tests never touch the real one.
    static func defaultLocation(environment: [String: String] = ProcessInfo.processInfo.environment) throws -> URL {
        let support = try environment["EVERLINE_DIR"].map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                       appropriateFor: nil, create: true)
        let folder = support.appendingPathComponent("Everline", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("notebook.sqlite")
    }
}
