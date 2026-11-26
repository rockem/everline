import CoreText
import SwiftUI

/// The bundled typefaces: Manrope for the interface and IBM Plex Mono for notes. They are registered in code, the same
/// way on macOS and iOS, so no Info.plist keys are needed. A missing font falls back to the system font.
enum Fonts {
    enum Weight: String {
        case regular = "Manrope-Regular"
        case medium = "Manrope-Medium"
        case semibold = "Manrope-SemiBold"
    }

    private static let registered: Void = {
        for url in Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    /// Makes the bundled fonts available to the process. Safe to call more than once.
    static func register() {
        _ = registered
    }

    /// An interface font at exactly `size`. Pass a `@ScaledMetric` value to follow Dynamic Type: the font does not
    /// scale itself, so the size is never scaled twice.
    static func ui(_ size: CGFloat, _ weight: Weight) -> Font {
        .custom(weight.rawValue, fixedSize: size)
    }
}
