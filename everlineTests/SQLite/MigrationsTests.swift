import XCTest
@testable import everline

/// The rules the schema enforces on bad data, and the migration files themselves.
@MainActor
final class MigrationsTests: DatabaseFileTestCase {
    func testMigrationFilesAreNumberedWithoutGapsOrDuplicates() throws {
        let names = try Migrations.files().map(\.name)

        XCTAssertFalse(names.isEmpty)
        XCTAssertEqual(names.map { String($0.prefix(4)) }, (1...names.count).map { String(format: "%04d", $0) })
        XCTAssertTrue(names.allSatisfy { $0.dropFirst(4).hasPrefix("-") && $0.count > 5 }, "\(names)")
    }

    func testTwoNotesCannotShareScopeAndDates() throws {
        try insertRow(scope: "day", start: "2026-10-28", end: "2026-10-28")

        XCTAssertThrowsError(try insertRow(scope: "day", start: "2026-10-28", end: "2026-10-28"))
    }

    func testStartAndEndDateMustBeSetTogether() throws {
        XCTAssertThrowsError(try insertRow(scope: nil, start: "2026-10-01", end: nil))
        XCTAssertThrowsError(try insertRow(scope: nil, start: nil, end: "2026-10-09"))
    }
}
