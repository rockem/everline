import SwiftUI

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

/// The palette sampled from the issue #21 mockups (light and dark). Text colors that carry meaning are at least 4.5:1
/// against the background; the placeholder is deliberately fainter (about 3:1).
enum Theme {
    static let background = Color(light: 0xFBFAF8, dark: 0x191816)
    static let divider = Color(light: 0xEFEEEC, dark: 0x292524)
    static let selectedPill = Color(light: 0xF5EDE8, dark: 0x342721)
    static let selectedOutline = Color(light: 0xF5EDE8, dark: 0x7A5A4C)
    static let selectedText = Color(light: 0x9E563C, dark: 0xE4A78D)
    static let primaryText = Color(light: 0x292524, dark: 0xF5F5F5)
    static let secondaryText = Color(light: 0x77716C, dark: 0xA5A09C)
    static let noteDot = Color(light: 0xAE6447, dark: 0xD89679)
    /// For the native text views, which need platform colors (they stay dynamic with the appearance).
    static let noteText = PlatformColor.dynamic(light: 0x44403C, dark: 0xE7E5E4)
    static let placeholder = PlatformColor.dynamic(light: 0x948F8A, dark: 0x6B6662)
}

#if os(macOS)
    typealias PlatformColor = NSColor
#else
    typealias PlatformColor = UIColor
#endif

private struct RGB {
    let red: Double
    let green: Double
    let blue: Double

    init(_ hex: UInt32) {
        red = Double((hex >> 16) & 0xFF) / 255
        green = Double((hex >> 8) & 0xFF) / 255
        blue = Double(hex & 0xFF) / 255
    }
}

extension PlatformColor {
    /// A color that switches between two values with the system appearance.
    static func dynamic(light: UInt32, dark: UInt32) -> PlatformColor {
        #if os(macOS)
            NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                let rgb = RGB(isDark ? dark : light)
                return NSColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
            }
        #else
            UIColor { traits in
                let rgb = RGB(traits.userInterfaceStyle == .dark ? dark : light)
                return UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
            }
        #endif
    }
}

private extension Color {
    init(light: UInt32, dark: UInt32) {
        #if os(macOS)
            self.init(nsColor: .dynamic(light: light, dark: dark))
        #else
            self.init(uiColor: .dynamic(light: light, dark: dark))
        #endif
    }
}
