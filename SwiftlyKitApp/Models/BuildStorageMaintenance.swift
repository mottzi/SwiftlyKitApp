import Observation
import SwiftlyKit

/// Cleanup available for a prepared package's SwiftPM build storage.
enum BuildStorageCleanup: Equatable {
    case cleanArtifacts
    case resetStorage
}

@Observable
/// Performs build-storage cleanup independently of the build workflow.
final class BuildStorageMaintenance {

    private(set) var activeCleanup: BuildStorageCleanup?

    private let swiftlyKit: SwiftlyKit

    init(swiftlyKit: SwiftlyKit) {
        self.swiftlyKit = swiftlyKit
    }

    /// Performs one cleanup using the package's prepared environment.
    func perform(_ cleanup: BuildStorageCleanup, using environment: LocalBuildEnvironment) async throws {
        guard !isRunning else { return }

        activeCleanup = cleanup
        defer { activeCleanup = nil }

        switch cleanup {
            case .cleanArtifacts: try await swiftlyKit.cleanBuildArtifacts(using: environment)
            case .resetStorage: try await swiftlyKit.resetBuildStorage(using: environment)
        }
    }

    /// Whether cleanup owns the package's build storage.
    var isRunning: Bool {
        activeCleanup != nil
    }

}
