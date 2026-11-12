@testable import everline
import XCTest

@MainActor
final class NotebookDatabaseTests: DatabaseFileTestCase {
    func testOpeningMigratesAFreshFile() throws {
        _ = try openDatabase()

        XCTAssertEqual(try strings("SELECT identifier FROM grdb_migrations"), ["0001-create-notes"])
    }

    func testReopeningTheFileKeepsOneMigrationRecord() throws {
        _ = try openDatabase()
        _ = try openDatabase()

        XCTAssertEqual(try count("SELECT COUNT(*) FROM grdb_migrations"), 1)
    }

    func testOpeningAnUnusablePathThrows() throws {
        XCTAssertThrowsError(try NotebookDatabase(path: path.deletingLastPathComponent()
                .appendingPathComponent("missing/notebook.sqlite")))

        try Data("this is not a database, just some text".utf8).write(to: path)
        XCTAssertThrowsError(try openDatabase())
    }

    func testDefaultLocationIsInsideApplicationSupportAndItsFolderExists() throws {
        let location = try NotebookDatabase.defaultLocation()

        XCTAssertEqual(location.lastPathComponent, "notebook.sqlite")
        XCTAssertEqual(location.deletingLastPathComponent().lastPathComponent, "Everline")
        XCTAssertTrue(location.path.contains("Application Support"))
        XCTAssertTrue(isDirectory(location.deletingLastPathComponent()))
    }

    func testDefaultLocationFollowsDirEnvVar() throws {
        let base = path.deletingLastPathComponent().appendingPathComponent("support")

        let location = try NotebookDatabase.defaultLocation(environment: ["EVERLINE_DIR": base.path])

        XCTAssertEqual(location.path, base.appendingPathComponent("Everline/notebook.sqlite").path)
        XCTAssertTrue(isDirectory(location.deletingLastPathComponent()))
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
