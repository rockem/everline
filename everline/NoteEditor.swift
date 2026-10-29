import AppKit
import SwiftUI

struct NoteEditor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasHorizontalScroller = false

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        textView.isEditable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.setAccessibilityIdentifier("note-editor")
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {}
}
