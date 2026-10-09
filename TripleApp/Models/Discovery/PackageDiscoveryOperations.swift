import Foundation
import Triple

/// Internal adapters for the observable package-discovery workflow.
nonisolated struct PackageDiscoveryOperations: Sendable {

    var hostReadiness: @Sendable () async throws -> HostReadiness
    var compatibleEnvironments: @Sendable (URL, BuildTarget) async throws -> EnvironmentChoices
    var prepare: @Sendable (EnvironmentAssessment, TripleEvent.Handler?) async throws -> LocalBuildEnvironment
    var configure: @Sendable (LocalBuildEnvironment, TripleEvent.Handler?) async throws -> PackageConfiguration

    init(triple: Triple) {
        hostReadiness = { try await Triple.hostReadiness() }
        compatibleEnvironments = { try await triple.compatibleEnvironments($0, for: $1) }
        prepare = { try await triple.prepare($0, onEvent: $1) }
        configure = { try await triple.configurePackage(using: $0, onEvent: $1) }
    }

}
