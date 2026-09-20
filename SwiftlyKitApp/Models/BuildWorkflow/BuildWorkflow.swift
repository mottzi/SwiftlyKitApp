import Foundation
import Observation
import SwiftlyKit

@Observable
/// Prepared package build, result publication, and live console workflow.
final class BuildWorkflow {

    /// Current execution state of the latest build.
    private(set) var state: BuildWorkflowState = .idle

    /// Verified runnable result of the latest successful build.
    private(set) var result: BuildResult?

    private(set) var isPublishing = false

    /// Live transcript of the latest build.
    let log: BuildLog

    @ObservationIgnored private var task: Task<Void, Never>?
    private let swiftlyKit: SwiftlyKit

    init(swiftlyKit: SwiftlyKit) {
        log = BuildLog()
        self.swiftlyKit = swiftlyKit
    }

    /// Starts a build from the prepared environment and a snapshot of the selected options.
    func start(
        _ preparedPackage: PreparedPackage,
        configuration: BuildConfiguration,
        stripBinary: Bool
    ) {

        guard !isRunning else { return }

        let request = BuildRequest(
            preparedPackage.selectedProduct,
            configuration: configuration,
            output: .buildStorage,
            strip: stripBinary
        )

        result = nil
        log.clear()
        state = .active(
            phase: .building,
            detail: "Starting the build."
        )
        log.appendBuildStart(
            for: preparedPackage,
            configuration: configuration,
            stripBinary: stripBinary
        )

        task = Task { [weak self] in
            guard let self else { return }
            await run(request, using: preparedPackage.environment)
        }
    }

    /// Whether a build or publication task still owns the workflow.
    var isRunning: Bool {
        state.isRunning || isPublishing
    }

    /// Publishes the successful result into an existing empty directory.
    func publishResult(into destination: URL) async throws -> BuildResult? {

        guard !isRunning else { return nil }
        guard let result else { return nil }

        isPublishing = true
        defer { isPublishing = false }
        return try await result.publish(into: destination)
    }

    /// Requests cancellation of the active build and its delegated command.
    func cancel() {
        guard state.canCancel else { return }

        state = .cancelling
        log.append("Cancelling the build.", kind: .status)
        task?.cancel()
    }

    /// Discards the completed package session's build result and console output.
    func discardSession() {
        guard !isRunning else { return }

        result = nil
        log.clear()
        state = .idle
    }

}

extension BuildWorkflow {

    private func run(_ request: BuildRequest, using environment: LocalBuildEnvironment) async {

        defer { task = nil }

        let onEvent: SwiftlyKitEvent.Handler = { [weak self] event in
            await self?.report(event)
        }

        do {
            let result = try await build(
                request,
                using: environment,
                onEvent: onEvent
            )

            try Task.checkCancellation()
            complete(with: result)
        } catch is CancellationError {
            completeCancellation()
        } catch {
            fail(with: error)
        }
    }

    private func build(
        _ request: BuildRequest,
        using environment: LocalBuildEnvironment,
        onEvent: @escaping SwiftlyKitEvent.Handler
    ) async throws -> BuildResult {

        do {
            return try await swiftlyKit.build(
                request,
                using: environment,
                onEvent: onEvent
            )
        } catch SwiftlyKitError.dependencyResolutionRequired {
            try Task.checkCancellation()

            state = .active(
                phase: .resolvingDependencies,
                detail: "Resolving package dependencies."
            )
            log.append("Dependency resolution is required before building.", kind: .status)

            try await swiftlyKit.resolveDependencies(
                in: request.scratchStorage,
                using: environment,
                onEvent: onEvent
            )
            try Task.checkCancellation()

            log.append("Dependencies resolved. Retrying the build.", kind: .status)
            return try await swiftlyKit.build(
                request,
                using: environment,
                onEvent: onEvent
            )
        }
    }

    private func complete(with result: BuildResult) {
        self.result = result
        state = .succeeded
        log.append(
            "Build succeeded: \(result.executable.path(percentEncoded: false))",
            kind: .success
        )
    }

    private func completeCancellation() {
        result = nil
        state = .cancelled
        log.append("Build cancelled.", kind: .status)
    }

    private func fail(with error: Error) {
        let description = error.localizedDescription

        result = nil
        state = .failed(description)
        log.append("Build failed.", kind: .failure)
    }

}

extension BuildWorkflow {

    private func report(_ event: SwiftlyKitEvent) {
        if case .progress(let progress) = event {
            report(progress)
        } else {
            log.append(event)
        }
    }

    private func report(_ progress: OperationProgress) {
        guard state.canCancel else { return }

        state = .active(
            phase: BuildWorkflowPhase(operation: progress.operation),
            detail: progress.detail
        )
        log.append(.progress(progress))
    }

}
