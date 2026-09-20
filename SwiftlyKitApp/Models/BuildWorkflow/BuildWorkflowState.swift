import Foundation
import SwiftlyKit

/// Current execution state of the latest build workflow.
enum BuildWorkflowState: Equatable {

    /// No build has started in this app session.
    case idle

    /// SwiftlyKit is performing one stage of the build.
    case active(phase: BuildWorkflowPhase, detail: String)

    /// The active build is stopping in response to cancellation.
    case cancelling

    /// The latest build produced a verified runnable result.
    case succeeded

    /// The latest build stopped with the supplied user-facing failure.
    case failed(String)

    /// The user cancelled the latest build.
    case cancelled

}

extension BuildWorkflowState {

    /// First source-located compiler error, or the retained failure if no such error exists.
    var failureSummary: String? {
        guard case .failed(let detail) = self else { return nil }

        for line in detail.split(whereSeparator: \.isNewline) {
            guard let range = line.range(of: #":\d+:\d+: (?:fatal )?error: "#, options: .regularExpression)
            else { continue }

            let message = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
            guard !message.isEmpty else { continue }
            return message.prefix(1).uppercased() + message.dropFirst()
        }

        return detail
    }

    /// Whether a build task still owns the workflow.
    var isRunning: Bool {
        switch self {
            case .active, .cancelling: true
            case .idle, .succeeded, .failed, .cancelled: false
        }
    }

    /// Whether the active build can accept a cancellation request.
    var canCancel: Bool {
        if case .active = self { true } else { false }
    }

}

/// User-visible stage of an active build workflow.
enum BuildWorkflowPhase: Equatable {

    /// SwiftPM is compiling or linking the selected product.
    case building

    /// SwiftPM is resolving package dependencies before a build retry.
    case resolvingDependencies

    /// SwiftlyKit is removing symbols from the verified executable.
    case stripping

}

extension BuildWorkflowPhase {

    /// Maps a build workflow progress operation to its user-visible stage.
    init(operation: OperationProgress.Operation) {
        switch operation {
            case .resolvingDependencies: self = .resolvingDependencies
            case .stripping: self = .stripping
            case .building, .preparingEnvironment, .removingEnvironment, .publishing,
                 .cleaningBuildArtifacts, .resettingBuildStorage: self = .building
        }
    }

}
