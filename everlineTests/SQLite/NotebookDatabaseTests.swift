import XCTest
@testable import everline

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
        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: location.deletingLastPathComponent().path,
                                                     isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }
}
