import Observation
import Triple

/// Cleanup available for a prepared package's SwiftPM build storage.
enum BuildStorageCleanup: Equatable {
    case cleanArtifacts
    case resetStorage
}

@Observable
/// Performs build-storage cleanup independently of the build workflow.
final class BuildStorageMaintenance {

    private(set) var activeCleanup: BuildStorageCleanup?

    private let activity: AppActivity
    private let triple: Triple

    init(triple: Triple, activity: AppActivity = AppActivity()) {
        self.activity = activity
        self.triple = triple
    }

    /// Performs one cleanup using the package's prepared environment.
    func perform(_ cleanup: BuildStorageCleanup, using environment: LocalBuildEnvironment) async throws {
        guard !isRunning else { return }

        let operation = activity.beginOperation()
        activeCleanup = cleanup
        defer {
            activeCleanup = nil
            activity.endOperation(operation)
        }

        switch cleanup {
            case .cleanArtifacts: try await triple.cleanBuildArtifacts(using: environment)
            case .resetStorage: try await triple.resetBuildStorage(using: environment)
        }
    }

    /// Whether cleanup owns the package's build storage.
    var isRunning: Bool {
        activeCleanup != nil
    }

}
