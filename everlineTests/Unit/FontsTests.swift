import AppKit
@testable import everline
import XCTest

final class FontsTests: XCTestCase {
    override func setUp() {
        Fonts.register()
    }

    func testTheBundledFontsLoad() {
        for name in ["Manrope-Regular", "Manrope-Medium", "Manrope-SemiBold", NoteTypography.fontName] {
            XCTAssertNotNil(NSFont(name: name, size: 16), "\(name) is not available")
        }
    }
}
