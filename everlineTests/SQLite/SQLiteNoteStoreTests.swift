import XCTest
@testable import everline

@MainActor
final class SQLiteNoteStoreTests: DatabaseFileTestCase {
    func testSavedNoteIsLoadedBack() throws {
        let store = try openStore()

        try store.save("hello", for: day("2026-10-28"))

        XCTAssertEqual(try week(of: store), [day("2026-10-28"): "hello"])
    }

    private func openStore() throws -> SQLiteNoteStore {
        SQLiteNoteStore(database: try openDatabase())
    }

    private func day(_ iso: String) -> Day {
        Day(iso: iso)!
    }

    private func week(of store: SQLiteNoteStore, scope: Scope = .day) throws -> [Day: String] {
        try store.notes(scope: scope, from: day("2026-10-26"), to: day("2026-11-01"))
    }

    func testNotesOutsideTheRangeAreNotLoaded() throws {
        let store = try openStore()

        try store.save("next week", for: day("2026-11-02"))
        try store.save("before", for: day("2026-10-25"))

        XCTAssertEqual(try week(of: store), [:])
    }

    func testSavingAgainReplacesTheTextAndKeepsTheRow() throws {
        let store = try openStore()

        try store.save("first", for: day("2026-10-28"))
        let idAndCreated = try strings("SELECT id || '|' || created_at FROM notes")
        try store.save("second", for: day("2026-10-28"))

        XCTAssertEqual(try week(of: store), [day("2026-10-28"): "second"])
        XCTAssertEqual(try strings("SELECT id || '|' || created_at FROM notes"), idAndCreated)
        XCTAssertEqual(try count("SELECT COUNT(*) FROM notes WHERE updated_at >= created_at"), 1)
    }

    func testSavingEmptyTextDeletesTheRow() throws {
        let store = try openStore()
        try store.save("hello", for: day("2026-10-28"))

        try store.save("", for: day("2026-10-28"))

        XCTAssertEqual(try count("SELECT COUNT(*) FROM notes"), 0)
    }

    func testSavingEmptyTextForAnUntouchedDayCreatesNoRow() throws {
        let store = try openStore()

        try store.save("", for: day("2026-10-28"))

        XCTAssertEqual(try count("SELECT COUNT(*) FROM notes"), 0)
    }

    func testWhitespaceOnlyTextIsStored() throws {
        let store = try openStore()

        try store.save(" ", for: day("2026-10-28"))

        XCTAssertEqual(try week(of: store), [day("2026-10-28"): " "])
    }

    func testNoteSurvivesReopeningTheFile() throws {
        try openStore().save("kept", for: day("2026-10-28"))

        let reopened = try openStore()

        XCTAssertEqual(try week(of: reopened), [day("2026-10-28"): "kept"])
    }

    func testOnlyTheRequestedScopeIsLoaded() throws {
        let store = try openStore()
        try store.save("day note", for: day("2026-10-28"))
        try insertRow(scope: "week", start: "2026-10-26", end: "2026-11-01")
        try insertRow(scope: nil, start: "2026-10-27", end: "2026-10-29")

        XCTAssertEqual(try week(of: store), [day("2026-10-28"): "day note"])
        XCTAssertEqual(try week(of: store, scope: .week), [day("2026-10-26"): "t"])
    }

    func testRowWithAnUnparseableDateIsSkipped() throws {
        let store = try openStore()
        try store.save("good", for: day("2026-10-28"))
        try insertRow(scope: "day", start: "2026-10-2x", end: "2026-10-2x")

        XCTAssertEqual(try week(of: store), [day("2026-10-28"): "good"])
    }

    func testLongTextRoundTrips() throws {
        let store = try openStore()
        let long = String(repeating: "line of a long note\n", count: 50_000)

        try store.save(long, for: day("2026-10-28"))

        XCTAssertEqual(try week(of: store)[day("2026-10-28")], long)
    }
}
