import SwiftUI

#if os(macOS)
import AppKit

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
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.setAccessibilityIdentifier("note-editor")
        // The view has no window yet; focus it once it is attached.
        DispatchQueue.main.async { textView.window?.makeFirstResponder(textView) }
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {}
}
#else
import UIKit

struct NoteEditor: UIViewRepresentable {
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.allowsEditingTextAttributes = false
        textView.font = UIFontMetrics(forTextStyle: .body)
            .scaledFont(for: .monospacedSystemFont(ofSize: 16, weight: .regular))
        textView.adjustsFontForContentSizeCategory = true
        textView.alwaysBounceVertical = true
        textView.accessibilityIdentifier = "note-editor"
        DispatchQueue.main.async { textView.becomeFirstResponder() }
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {}
}
#endif
