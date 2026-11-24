@testable import everline
import Foundation

/// A scheduler whose clock only moves when a test says so.
final class ManualScheduler: Scheduler {
    private final class Job: ScheduledWork {
        let due: TimeInterval
        var work: (() -> Void)?

        init(due: TimeInterval, work: @escaping () -> Void) {
            self.due = due
            self.work = work
        }

        func cancel() {
            work = nil
        }
    }

    private var now: TimeInterval = 0
    private var jobs: [Job] = []

    func after(_ seconds: TimeInterval, run work: @escaping () -> Void) -> ScheduledWork {
        let job = Job(due: now + seconds, work: work)
        jobs.append(job)
        return job
    }

    /// Moves the clock forward, running what falls due on the way in order.
    func advance(by seconds: TimeInterval) {
        let target = now + seconds
        while let job = jobs.filter({ $0.work != nil && $0.due <= target }).min(by: { $0.due < $1.due }) {
            now = job.due
            let work = job.work
            job.cancel()
            work?()
        }
        now = target
        jobs.removeAll { $0.work == nil }
    }
}
