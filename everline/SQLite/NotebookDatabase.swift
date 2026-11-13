import Foundation
import GRDB

/// The notebook's SQLite file: opens it and brings its schema up to date before anyone uses it.
final class NotebookDatabase {
    let queue: DatabaseQueue

    init(path: URL) throws {
        queue = try DatabaseQueue(path: path.path)
        try Migrations.migrate(queue)
    }

    /// `notebook.sqlite` inside `EVERLINE_DIR` when it is set, otherwise inside `Everline` in the user's Application
    /// Support folder. The folder is created when missing.
    static func defaultLocation(environment: [String: String] = ProcessInfo.processInfo.environment) throws -> URL {
        let folder = try environment["EVERLINE_DIR"].map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                       appropriateFor: nil, create: true)
                .appendingPathComponent("Everline", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("notebook.sqlite")
    }
}
