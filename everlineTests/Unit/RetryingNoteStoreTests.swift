@testable import everline
import XCTest

final class RetryingNoteStoreTests: XCTestCase {
    private var inner: FakeNoteStore!
    private var gaveUp: [Error]!
    private var store: RetryingNoteStore!

    override func setUp() {
        inner = FakeNoteStore()
        gaveUp = []
        store = RetryingNoteStore(inner, attempts: 3, pause: 0) { self.gaveUp.append($0) }
    }

    func testRetriesASaveThatFailsTwice() throws {
        inner.failuresLeft = 2

        try store.save("a", for: day)

        XCTAssertEqual(inner.saves.count, 3)
        XCTAssertEqual(inner.notes, [day: "a"])
        XCTAssertEqual(gaveUp.count, 0)
    }

    func testRetriesALoad() throws {
        inner.notes = [day: "a"]
        inner.failuresLeft = 1

        let loaded = try store.notes(scope: .day, from: day, to: day)

        XCTAssertEqual(loaded, [day: "a"])
        XCTAssertEqual(gaveUp.count, 0)
    }

    func testGivesUpAfterTheLastAttempt() {
        inner.failuresLeft = 3

        XCTAssertThrowsError(try store.save("a", for: day))

        XCTAssertEqual(inner.saves.count, 3)
        XCTAssertEqual(gaveUp.count, 1)
    }

    private let day = Day(2026, 10, 28)
}
