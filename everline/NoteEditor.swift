import SwiftUI

#if os(macOS)
    import AppKit

    /// The note's text view: takes keyboard focus as soon as it is attached to a window (whenever SwiftUI does that)
    /// and draws the placeholder while the page is empty, so it lines up with the real text.
    final class NoteTextView: NSTextView {
        var isShowingPlaceholder: Bool {
            string.isEmpty && !hasMarkedText()
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.window?.makeFirstResponder(self)
            }
        }

        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            guard isShowingPlaceholder else { return }
            let padding = textContainer?.lineFragmentPadding ?? 0
            let origin = textContainerOrigin
            let text = NSAttributedString(string: NoteTypography.placeholder,
                                          attributes: NoteTypography.attributes(color: Theme.placeholder))
            text.draw(in: NSRect(x: origin.x + padding, y: origin.y,
                                 width: max(0, bounds.width - 2 * (origin.x + padding)), height: bounds.height))
        }

        override func didChangeText() {
            super.didChangeText()
            needsDisplay = true
        }

        /// The line is taller than the font, so the caret is cut down to the font's height, centered.
        override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
            super.drawInsertionPoint(in: NoteTypography.caretRect(in: rect), color: color, turnedOn: flag)
        }
    }

    struct NoteEditor: NSViewRepresentable {
        @Binding var text: String

        func makeCoordinator() -> Coordinator {
            Coordinator(text: $text)
        }

        func makeNSView(context: Context) -> NSScrollView {
            let scrollView = NoteTextView.scrollableTextView()
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
            textView.textContainer?.lineFragmentPadding = 0
            textView.insertionPointColor = Theme.noteText
            textView.setAccessibilityPlaceholderValue(NoteTypography.placeholder)
            textView.setAccessibilityIdentifier("note-editor")
            applyTypography(to: textView)
        }

        /// Gives all text, and whatever is typed next, the note typography.
        private func applyTypography(to textView: NSTextView) {
            let attributes = NoteTypography.attributes()
            textView.font = NoteTypography.font
            textView.typingAttributes = attributes
            textView.defaultParagraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle
            textView.textStorage?.setAttributes(attributes, range: NSRange(location: 0,
                                                                          length: textView.textStorage?.length ?? 0))
        }

        func updateNSView(_ nsView: NSScrollView, context: Context) {
            context.coordinator.text = $text
            guard let textView = nsView.documentView as? NSTextView, textView.string != text else { return }
            textView.string = text
            applyTypography(to: textView)
        }

        final class Coordinator: NSObject, NSTextStorageDelegate, NSTextViewDelegate {
            var text: Binding<String>
            /// Per-editor undo history. The window's shared manager would keep actions targeting a text view that
            /// was already replaced (a new one is created per day), and undoing them crashes.
            private let editorUndoManager = UndoManager()

            init(text: Binding<String>) {
                self.text = text
            }

            func undoManager(for _: NSTextView) -> UndoManager? {
                editorUndoManager
            }

            func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions,
                             range _: NSRange, changeInLength _: Int) {
                guard editedMask.contains(.editedCharacters), text.wrappedValue != textStorage.string else { return }
                text.wrappedValue = textStorage.string
            }
        }
    }
#else
    import UIKit

    /// The note's text view: takes keyboard focus as soon as it is attached to a window (whenever SwiftUI does that),
    /// carries the note typography (also after a Dynamic Type change) and shows the placeholder while empty.
    final class NoteTextView: UITextView {
        private let placeholderLabel = UILabel()

        var isShowingPlaceholder: Bool {
            !placeholderLabel.isHidden
        }

        override init(frame: CGRect, textContainer: NSTextContainer?) {
            super.init(frame: frame, textContainer: textContainer)
            backgroundColor = .clear
            allowsEditingTextAttributes = false
            alwaysBounceVertical = true
            textContainer?.lineFragmentPadding = 0
            textContainerInset = .zero
            tintColor = Theme.noteText
            accessibilityIdentifier = "note-editor"
            placeholderLabel.numberOfLines = 0
            placeholderLabel.accessibilityElementsHidden = true
            addSubview(placeholderLabel)
            applyTypography()
            NotificationCenter.default.addObserver(self, selector: #selector(contentChanged),
                                                   name: UITextView.textDidChangeNotification, object: self)
            registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: NoteTextView, _) in
                view.applyTypography()
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override func caretRect(for position: UITextPosition) -> CGRect {
            NoteTypography.caretRect(in: super.caretRect(for: position))
        }

        override var text: String! {
            didSet { applyTypography() }
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            DispatchQueue.main.async { [weak self] in
                self?.becomeFirstResponder()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            let size = placeholderLabel.sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
            placeholderLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: size.height)
        }

        @objc private func contentChanged() {
            placeholderLabel.isHidden = !text.isEmpty
        }

        /// Gives all text, and whatever is typed next, the note typography.
        func applyTypography() {
            let attributes = NoteTypography.attributes()
            typingAttributes = attributes
            textStorage.setAttributes(attributes, range: NSRange(location: 0, length: textStorage.length))
            placeholderLabel.attributedText = NSAttributedString(
                string: NoteTypography.placeholder,
                attributes: NoteTypography.attributes(color: Theme.placeholder)
            )
            placeholderLabel.isHidden = !text.isEmpty
            setNeedsLayout()
        }
    }

    struct NoteEditor: UIViewRepresentable {
        @Binding var text: String

        func makeCoordinator() -> Coordinator {
            Coordinator(text: $text)
        }

        func makeUIView(context: Context) -> UITextView {
            let textView = NoteTextView()
            textView.delegate = context.coordinator
            textView.isEditable = true
            textView.text = text
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
