import AppKit
@testable import everline
import XCTest

final class AppLifecycleTests: XCTestCase {
    private let center = NotificationCenter()
    private var lifecycle: AppLifecycle!
    private var leavings = 0

    override func setUp() {
        lifecycle = AppLifecycle(center: center)
        lifecycle.onLeaving = { [self] in leavings += 1 }
    }

    func testLeavingTellsTheListener() {
        lifecycle.leaving()

        XCTAssertEqual(leavings, 1)
    }

    func testQuittingIsLeaving() {
        center.post(name: NSApplication.willTerminateNotification, object: nil)

        XCTAssertEqual(leavings, 1)
    }

    func testClosingAWindowIsLeaving() {
        center.post(name: NSWindow.willCloseNotification, object: nil)

        XCTAssertEqual(leavings, 1)
    }
}
