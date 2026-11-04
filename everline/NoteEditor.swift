import SwiftUI

#if os(macOS)
import AppKit

/// Takes keyboard focus as soon as it is attached to a window, whenever SwiftUI does that.
private final class FocusingTextView: NSTextView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.window?.makeFirstResponder(self)
        }
    }
}

struct NoteEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = FocusingTextView.scrollableTextView()
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        setupEditorView(textView, context)
        return scrollView
    }

    fileprivate func setupEditorView(_ textView: NSTextView, _ context: NoteEditor.Context) {
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.string = text
        // Storage-level observation also sees undo and redo, which never call textDidChange.
        textView.textStorage?.delegate = context.coordinator
        textView.isEditable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.setAccessibilityIdentifier("note-editor")
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.text = $text
        guard let textView = nsView.documentView as? NSTextView, textView.string != text else { return }
        textView.string = text
    }

    final class Coordinator: NSObject, NSTextStorageDelegate, NSTextViewDelegate {
        var text: Binding<String>
        /// Per-editor undo history. The window's shared manager would keep actions targeting a text view that
        /// was already replaced (a new one is created per day), and undoing them crashes.
        private let editorUndoManager = UndoManager()

        init(text: Binding<String>) {
            self.text = text
        }

        func undoManager(for view: NSTextView) -> UndoManager? {
            editorUndoManager
        }

        func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions,
                         range editedRange: NSRange, changeInLength delta: Int) {
            guard editedMask.contains(.editedCharacters), text.wrappedValue != textStorage.string else { return }
            text.wrappedValue = textStorage.string
        }
    }
}
#else
import UIKit

/// Takes keyboard focus as soon as it is attached to a window, whenever SwiftUI does that.
private final class FocusingTextView: UITextView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            self?.becomeFirstResponder()
        }
    }
}

struct NoteEditor: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = FocusingTextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.text = text
        textView.isEditable = true
        textView.allowsEditingTextAttributes = false
        textView.font = UIFontMetrics(forTextStyle: .body)
            .scaledFont(for: .monospacedSystemFont(ofSize: 16, weight: .regular))
        textView.adjustsFontForContentSizeCategory = true
        textView.alwaysBounceVertical = true
        textView.accessibilityIdentifier = "note-editor"
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.text = $text
        if uiView.text != text { uiView.text = text }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
    }
}
#endif
