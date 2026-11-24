import Foundation
#if os(macOS)
    import AppKit
#endif

/// Tells its listener that the app is leaving: about to quit, a window closing, or (on iOS) going to the background,
/// which the app reports with `leaving()`. It says nothing about what to do then.
final class AppLifecycle {
    var onLeaving: () -> Void = {}
    private let center: NotificationCenter
    private var observers: [NSObjectProtocol] = []

    init(center: NotificationCenter = .default) {
        self.center = center
        #if os(macOS)
            observers = [NSApplication.willTerminateNotification, NSWindow.willCloseNotification].map { name in
                center.addObserver(forName: name, object: nil, queue: nil) { [weak self] _ in self?.leaving() }
            }
        #endif
    }

    deinit {
        observers.forEach(center.removeObserver)
    }

    func leaving() {
        onLeaving()
    }
}
