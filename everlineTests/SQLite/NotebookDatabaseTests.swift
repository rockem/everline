@testable import everline
import XCTest

@MainActor
final class NotebookDatabaseTests: DatabaseFileTestCase {
    func testMigrationsRunOnce() throws {
        _ = try openDatabase()
        _ = try openDatabase()

        let expected = try Migrations.files().map(\.name)
        XCTAssertEqual(try count("SELECT COUNT(*) FROM grdb_migrations"), expected.count)
        XCTAssertEqual(try strings("SELECT identifier FROM grdb_migrations ORDER BY identifier"), expected)
    }

    func testFailWhenOpeningUnusablePath() throws {
        XCTAssertThrowsError(try NotebookDatabase(path: path.deletingLastPathComponent()
                .appendingPathComponent("missing/notebook.sqlite")))

        try Data("this is not a database, just some text".utf8).write(to: path)
        XCTAssertThrowsError(try openDatabase())
    }

    func testDefaultLocationIsInsideApplicationSupportAndItsFolderExists() throws {
        let location = try NotebookDatabase.defaultLocation(environment: [:])

        XCTAssertEqual(location.lastPathComponent, "notebook.sqlite")
        XCTAssertEqual(location.deletingLastPathComponent().lastPathComponent, "Everline")
        XCTAssertTrue(location.path.contains("Application Support"))
        XCTAssertTrue(isDirectory(location.deletingLastPathComponent()))
    }

    func testDefaultLocationFollowsDirEnvVar() throws {
        let base = path.deletingLastPathComponent().appendingPathComponent("notebook-dir")

        let location = try NotebookDatabase.defaultLocation(environment: ["EVERLINE_DIR": base.path])

        XCTAssertEqual(location.path, base.appendingPathComponent("notebook.sqlite").path)
        XCTAssertTrue(isDirectory(base))
    }

    func testRelativeDirEnvVarIsInsideTheTemporaryDirectory() throws {
        let name = "everline-test-\(UUID().uuidString)"
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(name, isDirectory: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }

        let location = try NotebookDatabase.defaultLocation(environment: ["EVERLINE_DIR": name])

        XCTAssertEqual(location.path, folder.appendingPathComponent("notebook.sqlite").path)
        XCTAssertTrue(isDirectory(folder))
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
