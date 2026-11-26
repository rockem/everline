@testable import everline
import SwiftUI
import ViewInspector
import XCTest

@MainActor
final class PageHeaderTests: XCTestCase {
    private let english = Locale(identifier: "en_US")

    func testTitleIsTheDay() throws {
        XCTAssertEqual(try pageTitleTextOf(pageHeader("2026-11-26")), "November 26")
    }

    private func pageTitleTextOf(_ header: PageHeader) throws -> String {
        try header.inspect().find(viewWithAccessibilityIdentifier: "page-title").text().string(locale: english)
    }

    private func pageHeader(_ iso: String) -> PageHeader {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return PageHeader(day: Day(iso: iso)!, calendar: DayCalendar(calendar))
    }
}
