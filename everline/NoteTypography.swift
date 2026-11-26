import Foundation

/// How note text looks: IBM Plex Mono Regular, 16 pt, line height 1.8, letter spacing -0.01 em. Bold lines will be
/// weight 600 once markdown styling arrives.
enum NoteTypography {
    static let fontName = "IBMPlexMono-Regular"
    static let size: CGFloat = 16
    static let lineHeightMultiple: CGFloat = 1.8
    static let letterSpacingEm: CGFloat = -0.01
    static let placeholder = "Write what happened, what mattered, or simply how the day felt..."

    /// The room a line has above and below the glyphs when its height is fixed at `lineHeightMultiple` x the font size,
    /// so text can be centered in its line the way CSS does, and the caret kept as tall as the font.
    static func halfLeading(fontHeight: CGFloat, fontSize: CGFloat) -> CGFloat {
        (fontSize * lineHeightMultiple - fontHeight) / 2
    }
}

#if os(macOS)
    import AppKit

    extension NoteTypography {
        static var font: NSFont {
            NSFont(name: fontName, size: size) ?? .monospacedSystemFont(ofSize: size, weight: .regular)
        }

        /// The attributes every character of a note carries, typed or loaded.
        static func attributes(color: NSColor = Theme.noteText) -> [NSAttributedString.Key: Any] {
            let font = font
            let style = NSMutableParagraphStyle()
            style.minimumLineHeight = font.pointSize * lineHeightMultiple
            style.maximumLineHeight = font.pointSize * lineHeightMultiple
            return [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: style,
                .kern: letterSpacingEm * font.pointSize,
                .baselineOffset: halfLeading(fontHeight: font.ascender - font.descender, fontSize: font.pointSize)
            ]
        }

        /// The caret for a line: as tall as the font and centered, not as tall as the whole (taller) line.
        static func caretRect(in line: NSRect) -> NSRect {
            let font = font
            let height = font.ascender - font.descender
            return NSRect(x: line.minX, y: line.midY - height / 2, width: line.width, height: height)
        }
    }
#else
    import UIKit

    extension NoteTypography {
        /// Scales with Dynamic Type, relative to body.
        static var font: UIFont {
            let base = UIFont(name: fontName, size: size) ?? .monospacedSystemFont(ofSize: size, weight: .regular)
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: base)
        }

        /// The attributes every character of a note carries, typed or loaded.
        static func attributes(color: UIColor = Theme.noteText) -> [NSAttributedString.Key: Any] {
            let font = font
            let style = NSMutableParagraphStyle()
            style.minimumLineHeight = font.pointSize * lineHeightMultiple
            style.maximumLineHeight = font.pointSize * lineHeightMultiple
            return [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: style,
                .kern: letterSpacingEm * font.pointSize,
                .baselineOffset: halfLeading(fontHeight: font.ascender - font.descender, fontSize: font.pointSize)
            ]
        }

        /// The caret for a line: as tall as the font and centered, not as tall as the whole (taller) line.
        static func caretRect(in line: CGRect) -> CGRect {
            let font = font
            let height = font.ascender - font.descender
            return CGRect(x: line.minX, y: line.midY - height / 2, width: line.width, height: height)
        }
    }
#endif
