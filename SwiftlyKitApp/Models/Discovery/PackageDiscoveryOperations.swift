import Foundation
import SwiftlyKit

/// Internal adapters for the observable package-discovery workflow.
nonisolated struct PackageDiscoveryOperations: Sendable {

    var hostReadiness: @Sendable () async throws -> HostReadiness
    var compatibleEnvironments: @Sendable (URL, BuildTarget) async throws -> EnvironmentChoices
    var prepare: @Sendable (EnvironmentAssessment, SwiftlyKitEvent.Handler?) async throws -> LocalBuildEnvironment
    var configure: @Sendable (LocalBuildEnvironment, SwiftlyKitEvent.Handler?) async throws -> PackageConfiguration

    init(swiftlyKit: SwiftlyKit) {
        hostReadiness = { try await SwiftlyKit.hostReadiness() }
        compatibleEnvironments = { try await swiftlyKit.compatibleEnvironments($0, for: $1) }
        prepare = { try await swiftlyKit.prepare($0, onEvent: $1) }
        configure = { try await swiftlyKit.configurePackage(using: $0, onEvent: $1) }
    }

}
