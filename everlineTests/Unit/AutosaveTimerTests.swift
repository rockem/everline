@testable import everline
import XCTest

final class AutosaveTimerTests: XCTestCase {
    private var scheduler: ManualScheduler!
    private var timer: AutosaveTimer!
    private var fires = 0

    override func setUp() {
        scheduler = ManualScheduler()
        timer = AutosaveTimer(timing: AutosaveTiming(idle: 2, deadline: 5), scheduler: scheduler) { [self] in
            fires += 1
        }
    }

    func testNeverFiresWithoutAnEdit() {
        scheduler.advance(by: 60)

        XCTAssertEqual(fires, 0)
    }

    func testFiresAfterAPause() {
        timer.edited()

        scheduler.advance(by: 1.9)
        XCTAssertEqual(fires, 0)
        scheduler.advance(by: 0.1)
        XCTAssertEqual(fires, 1)
    }

    func testContinuousEditsFireAtTheDeadline() {
        for _ in 1 ... 4 {
            timer.edited()
            scheduler.advance(by: 1)
        }
        XCTAssertEqual(fires, 0)

        timer.edited()
        scheduler.advance(by: 1)

        XCTAssertEqual(fires, 1)
    }

    func testFiringCancelsTheOtherTimer() {
        timer.edited()

        scheduler.advance(by: 60)

        XCTAssertEqual(fires, 1)
    }

    func testStopCancelsBoth() {
        timer.edited()

        timer.stop()
        scheduler.advance(by: 60)

        XCTAssertEqual(fires, 0)
    }

    func testAnEditAfterFiringStartsANewCycle() {
        timer.edited()
        scheduler.advance(by: 2)

        timer.edited()
        scheduler.advance(by: 2)

        XCTAssertEqual(fires, 2)
    }
}
