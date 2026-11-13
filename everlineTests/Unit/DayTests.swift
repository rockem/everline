import XCTest
@testable import everline

final class DayTests: XCTestCase {
    func testIsoStringRoundTrip() {
        XCTAssertEqual(Day(iso: "2026-10-28")?.id, "2026-10-28")
    }

    func testRejectsMalformedAndImpossibleDates() {
        for text in ["nope", "", "2026-02-30", "2026-13-01", "2026-1-5", "2026-10-28-01", "2026-00-10"] {
            XCTAssertNil(Day(iso: text), text)
        }
    }

    func testLeapDayExistsOnlyInLeapYears() {
        XCTAssertNotNil(Day(iso: "2028-02-29"))
        XCTAssertNil(Day(iso: "2027-02-29"))
    }
}
