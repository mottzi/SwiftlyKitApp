import Foundation
import Observation
import SwiftlyKit

/// Current state of executable-product discovery for the selected package and environment.
enum ProductDiscoveryState: Equatable {

    /// No package environment is being inspected.
    case idle

    /// SwiftlyKit is preparing an environment or inspecting the package.
    case discovering(detail: String)

    /// Product discovery is paused until the user approves required installations.
    case installationRequired(InstallationApprovalRequest)

    /// Executable products were discovered in name order.
    case ready

    /// Package inspection succeeded without finding an executable product.
    case empty

    /// SwiftlyKit could not complete product discovery.
    case failed(SwiftlyKitError)

}

@Observable
/// Prepares one selected environment and discovers its executable package products.
final class ProductDiscovery {

    /// Current executable-product discovery state.
    private(set) var state: ProductDiscoveryState = .idle

    /// Installation that discovery is waiting for the user to approve.
    private(set) var installationApprovalRequest: InstallationApprovalRequest?

    /// Revision that requests another app-level discovery task.
    private(set) var retryRevision = 0

    /// Most recently discovered executable products.
    private(set) var availableProducts: [ExecutableProduct] = []

    /// Selected executable package product.
    var selectedProduct: ExecutableProduct?

    /// Whether product discovery has one valid selection.
    var hasValidSelection: Bool {
        guard case .ready = state else { return false }
        return selectedProduct != nil
    }

    @ObservationIgnored private var pendingInstallationContext: Context?
    @ObservationIgnored private var approvedInstallationContext: Context?
    @ObservationIgnored private var lastPreparedContext: Context?
    @ObservationIgnored private var installationCancellationSnapshot: Snapshot?
    @ObservationIgnored private var contextToSkip: Context?
    private let swiftlyKit: SwiftlyKit

    init(swiftlyKit: SwiftlyKit) {
        self.swiftlyKit = swiftlyKit
    }

    /// Prepares the selected environment and discovers its executable products.
    func discover(
        in packageRoot: URL,
        for target: BuildTarget,
        toolchain: ToolchainSelection,
        environmentChoices: EnvironmentChoices
    ) async {
        let context = Context(
            packageRoot: packageRoot,
            target: target,
            toolchain: toolchain
        )

        if contextToSkip == context {
            contextToSkip = nil
            return
        }

        do {
            let assessment = try environmentChoices.select(toolchain)

            if assessment.requiresInstallation, approvedInstallationContext != context {
                guard !Task.isCancelled else { return }

                let approval = InstallationApprovalRequest(
                    swiftVersion: assessment.swiftVersion,
                    staticLinuxSDKVersion: assessment.staticLinuxSDK.version,
                    requiredComponents: assessment.requiredComponents
                )
                installationCancellationSnapshot = cancellationSnapshot()
                pendingInstallationContext = context
                installationApprovalRequest = approval
                state = .installationRequired(approval)
                return
            }

            pendingInstallationContext = nil
            installationApprovalRequest = nil
            state = .discovering(
                detail: "Preparing Swift \(assessment.swiftVersion) for product discovery."
            )

            let environment = try await swiftlyKit.prepare(
                assessment,
                onEvent: { [weak self] event in
                    guard case .progress(let progress) = event else { return }
                    await self?.report(progress)
                }
            )

            lastPreparedContext = context
            state = .discovering(detail: "Inspecting executable package products.")

            let products = try await swiftlyKit.executableProducts(using: environment)

            guard !Task.isCancelled else { return }

            replaceProducts(with: Array(products))
        } catch is CancellationError {
            // a replacement task owns the next state transition
        } catch let error as SwiftlyKitError {
            guard !Task.isCancelled else { return }
            state = .failed(error)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(
                .packageInspectionFailed("An unexpected product discovery error occurred.")
            )
        }
    }

    /// Requests another discovery through the existing app-level task.
    func requestRetry() {
        retryRevision += 1
    }

    /// Approves the pending installation and resumes product discovery.
    func approveInstallation() {
        guard let pendingInstallationContext else { return }

        approvedInstallationContext = pendingInstallationContext
        installationApprovalRequest = nil
        self.pendingInstallationContext = nil
        installationCancellationSnapshot = nil
        retryRevision += 1
    }

    /// Declines the pending installation and returns the last prepared toolchain when possible.
    func cancelInstallation() -> ToolchainSelection? {
        guard let pendingInstallationContext else { return nil }

        let cancellationSnapshot = installationCancellationSnapshot
        installationApprovalRequest = nil
        self.pendingInstallationContext = nil
        installationCancellationSnapshot = nil

        guard
            let lastPreparedContext,
            lastPreparedContext.packageRoot == pendingInstallationContext.packageRoot,
            lastPreparedContext.target == pendingInstallationContext.target,
            lastPreparedContext.toolchain != pendingInstallationContext.toolchain
        else { return nil }

        if let cancellationSnapshot {
            state = cancellationSnapshot.state
            selectedProduct = cancellationSnapshot.selectedProduct
            contextToSkip = cancellationSnapshot.context
        }

        return lastPreparedContext.toolchain
    }

    /// Clears products that belong to a package or environment that is no longer selected.
    func clear() {
        state = .idle
        availableProducts = []
        selectedProduct = nil
        resetContext()
    }

    /// Invalidates discovery while a replacement result is prepared.
    func invalidate() {
        state = .idle
        resetContext()
    }

    /// Replaces the available products after discovery completes.
    func replaceProducts(with products: [ExecutableProduct]) {
        availableProducts = products
        selectedProduct = products.first
        state = products.isEmpty ? .empty : .ready
    }

}

extension ProductDiscovery {

    private func report(_ progress: OperationProgress) {
        guard case .discovering = state else { return }
        state = .discovering(detail: progress.detail)
    }

    private func cancellationSnapshot() -> Snapshot? {
        guard let lastPreparedContext else { return nil }

        switch state {
            case .ready, .empty, .failed:
                return Snapshot(
                    context: lastPreparedContext,
                    state: state,
                    selectedProduct: selectedProduct
                )
            case .idle, .discovering, .installationRequired:
                return nil
        }
    }

    private func resetContext() {
        installationApprovalRequest = nil
        pendingInstallationContext = nil
        approvedInstallationContext = nil
        lastPreparedContext = nil
        installationCancellationSnapshot = nil
        contextToSkip = nil
    }

    private struct Context: Equatable {
        let packageRoot: URL
        let target: BuildTarget
        let toolchain: ToolchainSelection
    }

    private struct Snapshot {
        let context: Context
        let state: ProductDiscoveryState
        let selectedProduct: ExecutableProduct?
    }

}
