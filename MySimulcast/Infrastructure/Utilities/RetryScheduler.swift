import Foundation

struct RetryScheduler {
    private var attempt = 0
    private let base: TimeInterval = 2
    private let cap: TimeInterval = 30

    mutating func nextDelay() -> TimeInterval {
        let delay = min(base * pow(2, Double(attempt)), cap)
        attempt += 1
        return delay
    }

    mutating func reset() {
        attempt = 0
    }
}
