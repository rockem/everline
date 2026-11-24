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

    /// An interface font that grows with Dynamic Type, relative to a text style.
    static func ui(_ size: CGFloat, _ weight: Weight, relativeTo style: Font.TextStyle) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }
}
