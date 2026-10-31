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
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.setAccessibilityIdentifier("note-editor")
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
        textView.font = .preferredFont(forTextStyle: .body)
        textView.alwaysBounceVertical = true
        textView.accessibilityIdentifier = "note-editor"
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {}
}
#endif
