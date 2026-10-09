import Foundation
import Observation
import SwiftlyKit

@Observable
/// Prepared package build, result export, and live console workflow.
final class BuildWorkflow {

    /// Current execution state of the latest build.
    private(set) var state: BuildWorkflowState = .idle

    /// Verified runnable result of the latest successful build.
    private(set) var result: BuildResult?

    private(set) var identity: BuildIdentity?

    private(set) var isExporting = false

    /// Requests presentation of installation approval for automatic compiler recovery.
    private(set) var installationApprovalRevision = 0

    /// Live transcript of the latest build.
    let log: BuildLog

    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var buildID = UUID()
    @ObservationIgnored private var pendingRecovery: PendingRecovery?
    private let activity: AppActivity
    private let operations: BuildWorkflowOperations

    init(swiftlyKit: SwiftlyKit, activity: AppActivity = AppActivity()) {
        self.activity = activity
        log = BuildLog()
        operations = BuildWorkflowOperations(swiftlyKit: swiftlyKit)
    }

    init(operations: BuildWorkflowOperations, activity: AppActivity = AppActivity()) {
        self.activity = activity
        log = BuildLog()
        self.operations = operations
    }

    /// Starts a build from the prepared environment and a snapshot of the selected options.
    func start(
        _ preparedPackage: PreparedPackage,
        target: BuildTarget,
        configuration: BuildConfiguration,
        stripBinary: Bool,
        environmentChoices: EnvironmentChoices? = nil,
        toolchain: ToolchainSelection = .automatic
    ) {

        guard !isRunning else { return }
        let buildID = UUID()
        self.buildID = buildID
        pendingRecovery = nil

        let request = BuildRequest(
            preparedPackage.selectedProduct,
            configuration: configuration,
            output: .buildStorage,
            strip: stripBinary
        )

        identity = BuildIdentity(
            product: preparedPackage.selectedProduct.name,
            target: target,
            configuration: configuration,
            swiftVersion: preparedPackage.environment.swiftVersion,
            stripBinary: stripBinary
        )
        result = nil
        log.clear()
        state = .active(
            phase: .inspectingPackage,
            detail: "Validating dependencies before compilation."
        )
        log.appendBuildStart(
            for: preparedPackage,
            configuration: configuration,
            stripBinary: stripBinary
        )

        let operation = activity.beginOperation()
        task = Task { [weak self, activity] in
            defer { activity.endOperation(operation) }
            guard let self else { return }
            await run(
                request,
                using: .prepared(preparedPackage.environment),
                choices: environmentChoices,
                toolchain: toolchain,
                buildID: buildID
            )
        }
    }

    /// Whether a build or export task still owns the workflow.
    var isRunning: Bool {
        state.isRunning || isExporting
    }

    /// Exports the successful result into an existing empty directory.
    func exportResult(into destination: URL) async throws -> BuildResult? {

        guard !isRunning else { return nil }
        guard let result else { return nil }

        let operation = activity.beginOperation()
        isExporting = true
        defer {
            isExporting = false
            activity.endOperation(operation)
        }
        return try await result.export(to: destination, policy: .requireExistingEmptyDirectory)
    }

    /// Requests cancellation of the active build and its delegated command.
    func cancel() {
        guard state.canCancel else { return }

        if case .installationRequired = state {
            pendingRecovery = nil
            completeCancellation()
            return
        }

        state = .cancelling
        log.append("Cancelling the build.", kind: .status)
        task?.cancel()
    }

    /// Discards the completed package session's build result and console output.
    func discardSession() {
        guard !isRunning else { return }

        buildID = UUID()
        pendingRecovery = nil

        result = nil
        identity = nil
        log.clear()
        state = .idle
    }

    /// Presents the retained recovery approval again without restarting dependency inspection.
    func requestInstallationApproval() {
        guard case .installationRequired = state else { return }
        installationApprovalRevision += 1
    }

    /// Accepts only the retained recovery assessment, then resumes the same captured build request.
    func approveInstallation() {
        guard let pendingRecovery, case .installationRequired = state else { return }
        self.pendingRecovery = nil
        let buildID = self.buildID
        state = .active(phase: .preparingEnvironment, detail: "Preparing the approved Swift environment.")
        let operation = activity.beginOperation()
        task = Task { [weak self, activity] in
            defer { activity.endOperation(operation) }
            guard let self else { return }
            await run(
                pendingRecovery.request,
                using: .approved(pendingRecovery.assessment),
                choices: pendingRecovery.choices,
                toolchain: pendingRecovery.toolchain,
                buildID: buildID
            )
        }
    }

}

extension BuildWorkflow {

    private func run(
        _ request: BuildRequest,
        using source: EnvironmentSource,
        choices: EnvironmentChoices?,
        toolchain: ToolchainSelection,
        buildID: UUID
    ) async {

        defer { if self.buildID == buildID { task = nil } }

        let onEvent: SwiftlyKitEvent.Handler = { [weak self] event in
            await self?.report(event, buildID: buildID)
        }

        do {
            let environment: LocalBuildEnvironment
            switch source {
                case .prepared(let prepared):
                    environment = prepared

                case .approved(let assessment):
                    environment = try await prepare(assessment, onEvent: onEvent, buildID: buildID)
            }

            let result = try await build(
                request,
                using: environment,
                choices: choices,
                toolchain: toolchain,
                onEvent: onEvent,
                buildID: buildID
            )

            try Task.checkCancellation()
            guard self.buildID == buildID else { return }
            guard let result else { return }
            complete(with: result)
        } catch is CancellationError {
            guard self.buildID == buildID else { return }
            completeCancellation()
        } catch {
            guard self.buildID == buildID else { return }
            fail(with: error)
        }
    }

    private func prepare(
        _ assessment: EnvironmentAssessment,
        onEvent: @escaping SwiftlyKitEvent.Handler,
        buildID: UUID
    ) async throws -> LocalBuildEnvironment {

        let environment = try await operations.prepare(assessment, onEvent)
        try Task.checkCancellation()
        guard self.buildID == buildID else { throw CancellationError() }
        updateIdentity(swiftVersion: environment.swiftVersion)
        return environment
    }

    private func build(
        _ request: BuildRequest,
        using environment: LocalBuildEnvironment,
        choices: EnvironmentChoices?,
        toolchain: ToolchainSelection,
        onEvent: @escaping SwiftlyKitEvent.Handler,
        buildID: UUID
    ) async throws -> BuildResult? {

        var environment = environment
        while true {
            try Task.checkCancellation()
            do {
                return try await operations.build(request, environment, onEvent)
            } catch let error as SwiftlyKitError {
                guard self.buildID == buildID else { throw CancellationError() }
                guard let assessment = choices?.recoveryAssessment(after: error, for: toolchain)
                else { throw error }
                guard assessment.swiftVersion > environment.swiftVersion else { throw error }

                log.append(
                    "Host compilation failed with Swift \(environment.swiftVersion). "
                        + "Trying compatible Swift \(assessment.swiftVersion).",
                    kind: .status
                )
                if assessment.requiresInstallation {
                    pendingRecovery = PendingRecovery(
                        request: request,
                        assessment: assessment,
                        choices: choices,
                        toolchain: toolchain
                    )
                    state = .installationRequired(InstallationApprovalRequest(
                        swiftVersion: assessment.swiftVersion,
                        staticLinuxSDKVersion: assessment.staticLinuxSDK.version,
                        requiredComponents: assessment.requiredComponents
                    ))
                    installationApprovalRevision += 1
                    return nil
                }
                state = .active(phase: .preparingEnvironment, detail: "Preparing Swift \(assessment.swiftVersion).")
                environment = try await prepare(assessment, onEvent: onEvent, buildID: buildID)
            }
        }
    }

    private func updateIdentity(swiftVersion: SwiftVersion) {
        guard let identity else { return }
        self.identity = BuildIdentity(
            product: identity.product,
            target: identity.target,
            configuration: identity.configuration,
            swiftVersion: swiftVersion,
            stripBinary: identity.stripBinary
        )
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
        identity = nil
        state = .cancelled
        log.append("Build cancelled.", kind: .status)
    }

    private func fail(with error: Error) {
        let description = error.localizedDescription

        result = nil
        identity = nil
        state = .failed(description)
        log.append(description, kind: .failure)
    }

}

extension BuildWorkflow {

    private func report(_ event: SwiftlyKitEvent, buildID: UUID) {
        guard self.buildID == buildID, !Task.isCancelled, case .active = state else { return }
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

extension BuildWorkflow {

    /// Starting environment or approved recovery assessment for one build task.
    private enum EnvironmentSource {

        /// Environment captured before the build starts.
        case prepared(LocalBuildEnvironment)

        /// Accepted recovery assessment used to prepare the environment.
        case approved(EnvironmentAssessment)

    }

    /// Captured build choices retained while recovery waits for installation approval.
    private struct PendingRecovery {
        let request: BuildRequest
        let assessment: EnvironmentAssessment
        let choices: EnvironmentChoices?
        let toolchain: ToolchainSelection
    }

}

/// Internal adapters keep build orchestration testable without spawning real compilers.
nonisolated struct BuildWorkflowOperations: Sendable {

    var build: @Sendable (BuildRequest, LocalBuildEnvironment, SwiftlyKitEvent.Handler?) async throws -> BuildResult
    var prepare: @Sendable (EnvironmentAssessment, SwiftlyKitEvent.Handler?) async throws -> LocalBuildEnvironment

    init(swiftlyKit: SwiftlyKit) {
        build = { try await swiftlyKit.build($0, using: $1, dependencies: .resolveIfNeeded, onEvent: $2) }
        prepare = { try await swiftlyKit.prepare($0, onEvent: $1) }
    }

}
