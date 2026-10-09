import Testing
@testable import SwiftlyKitApp

@MainActor
@Suite("Update restart deferral")
struct AppActivityTests {

    @Test("A restart waits for operations in every window")
    func waitsForAllWindows() {

        let activity = AppActivity()
        let first = activity.beginOperation()
        let second = activity.beginOperation()
        var restarts = 0
        activity.whenIdle { restarts += 1 }

        activity.endOperation(first)
        #expect(activity.isBusy)
        #expect(restarts == 0)
        activity.endOperation(first)
        #expect(restarts == 0)

        activity.endOperation(second)
        #expect(!activity.isBusy)
        #expect(restarts == 1)
        activity.endOperation(second)
        #expect(restarts == 1)
    }

    @Test("Idle operations do not delay a restart")
    func idleRestart() {
        let activity = AppActivity()
        var restarted = false
        activity.whenIdle { restarted = true }
        #expect(restarted)
    }

    @Test("An idle callback that starts work delays the remaining callbacks")
    func callbackStartsWork() {

        let activity = AppActivity()
        let first = activity.beginOperation()
        var second = first
        var restarted = false
        activity.whenIdle { second = activity.beginOperation() }
        activity.whenIdle { restarted = true }

        activity.endOperation(first)
        #expect(!restarted)
        activity.endOperation(second)
        #expect(restarted)
    }

}
