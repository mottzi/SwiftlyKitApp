import Foundation
import Observation

@Observable
/// Active operations across all build windows.
final class AppActivity {

    private var operations: Set<UUID> = []
    @ObservationIgnored private var idleActions: [() -> Void] = []

    /// Registers an operation before its asynchronous work starts.
    func beginOperation() -> UUID {
        let operation = UUID()
        operations.insert(operation)
        return operation
    }

    /// Completes an operation and resumes pending actions after all operations finish.
    func endOperation(_ operation: UUID) {

        guard operations.remove(operation) != nil else { return }
        guard !isBusy else { return }

        let actions = idleActions
        idleActions.removeAll()
        for action in actions { whenIdle(action) }
    }

    /// Whether any window still has active work.
    var isBusy: Bool { !operations.isEmpty }

    /// Runs an action after the current operations finish.
    func whenIdle(_ action: @escaping () -> Void) {
        guard isBusy else {
            action()
            return
        }
        idleActions.append(action)
    }

}
