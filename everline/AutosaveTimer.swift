import Foundation

/// How long typing may pause before a save, and the most a save may be put off while typing goes on.
struct AutosaveTiming {
    let idle: TimeInterval
    let deadline: TimeInterval

    static let standard = AutosaveTiming(idle: 2, deadline: 5)
}

/// Fires once after a pause in editing, or at the deadline when editing never pauses, whichever comes first.
final class AutosaveTimer {
    private let timing: AutosaveTiming
    private let scheduler: Scheduler
    private let onFire: () -> Void
    private var idle: ScheduledWork?
    private var deadline: ScheduledWork?

    init(timing: AutosaveTiming, scheduler: Scheduler, onFire: @escaping () -> Void) {
        self.timing = timing
        self.scheduler = scheduler
        self.onFire = onFire
    }

    /// An edit happened: the pause starts over, and the deadline starts if no save is already waiting.
    func edited() {
        idle?.cancel()
        idle = scheduler.after(timing.idle) { [weak self] in self?.fire() }
        if deadline == nil {
            deadline = scheduler.after(timing.deadline) { [weak self] in self?.fire() }
        }
    }

    private func fire() {
        stop()
        onFire()
    }

    func stop() {
        idle?.cancel()
        deadline?.cancel()
        idle = nil
        deadline = nil
    }
}
