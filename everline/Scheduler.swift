import Foundation

/// Runs work later. Tests swap in a clock they move by hand.
protocol Scheduler {
    func after(_ seconds: TimeInterval, run work: @escaping () -> Void) -> ScheduledWork
}

protocol ScheduledWork {
    func cancel()
}

extension DispatchWorkItem: ScheduledWork {}

struct MainQueueScheduler: Scheduler {
    func after(_ seconds: TimeInterval, run work: @escaping () -> Void) -> ScheduledWork {
        let item = DispatchWorkItem(block: work)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
        return item
    }
}
