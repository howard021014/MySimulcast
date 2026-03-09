import Testing
import Foundation
@testable import MySimulcast

@Suite("RetryScheduler")
struct RetrySchedulerTests {

    @Test("Delay sequence follows exponential backoff")
    func delaySequence() {
        var scheduler = RetryScheduler()
        #expect(scheduler.nextDelay() == 2)
        #expect(scheduler.nextDelay() == 4)
        #expect(scheduler.nextDelay() == 8)
        #expect(scheduler.nextDelay() == 16)
    }

    @Test("Delay caps at 30 seconds")
    func delayCap() {
        var scheduler = RetryScheduler()
        // 2, 4, 8, 16, 32->30
        for _ in 0..<4 { _ = scheduler.nextDelay() }
        #expect(scheduler.nextDelay() == 30)
        #expect(scheduler.nextDelay() == 30)
    }

    @Test("Reset restarts the sequence")
    func reset() {
        var scheduler = RetryScheduler()
        _ = scheduler.nextDelay() // 2
        _ = scheduler.nextDelay() // 4
        scheduler.reset()
        #expect(scheduler.nextDelay() == 2)
    }
}
