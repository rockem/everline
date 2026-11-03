import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Light values sampled from the US-3 mockup, dark values from a reference dark-mode screenshot.
enum Theme {
    static let background = Color(light: 0xFAF9F6, dark: 0x2D2E2E)
    static let divider = Color(light: 0xEBEAE8, dark: 0x4C4D4D)
    static let pill = Color(light: 0x292524, dark: 0x969797)
    static let onPill = Color(light: 0xFFFFFF, dark: 0x2D2E2E)
    static let dayNumber = Color(light: 0x77716C, dark: 0x979797)
    static let weekdayLabel = Color(light: 0xA5A09C, dark: 0x818282)
    static let accent = Color(light: 0xBB6A4B, dark: 0xC47168)
}

private extension Color {
    init(light: UInt32, dark: UInt32) {
        struct RGB {
            let red: Double
            let green: Double
            let blue: Double

            init(_ hex: UInt32) {
                red = Double((hex >> 16) & 0xFF) / 255
                green = Double((hex >> 8) & 0xFF) / 255
                blue = Double(hex & 0xFF) / 255
            }
        }
        #if os(macOS)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let rgb = RGB(isDark ? dark : light)
            return NSColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
        })
        #else
        self.init(uiColor: UIColor { traits in
            let rgb = RGB(traits.userInterfaceStyle == .dark ? dark : light)
            return UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
        })
        #endif
    }
}
