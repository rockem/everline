import AppKit
import SwiftUI

/// Puts one SwiftUI view in a real key window so component tests can drive it in-process.
@MainActor
final class HostedView<Content: View> {
    let window: NSWindow
    private let hosting: NSHostingView<Content>

    init(_ content: Content, size: CGSize = CGSize(width: 700, height: 500)) {
        hosting = NSHostingView(rootView: content)
        window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                          backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        window.makeKeyAndOrderFront(nil)
    }

    func update(_ content: Content) {
        hosting.rootView = content
    }

    /// Spins the run loop so deferred work (focus, SwiftUI updates) happens.
    func settle(_ seconds: TimeInterval = 0.2) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    func find<T: NSView>(_ type: T.Type) -> T? {
        func search(_ view: NSView) -> T? {
            if let match = view as? T { return match }
            for subview in view.subviews {
                if let match = search(subview) { return match }
            }
            return nil
        }
        return search(hosting)
    }

    func close() {
        window.close()
    }
}
