import Foundation
import Observation
import SwiftlyKit

/// Current state of executable-product discovery for the selected package and environment.
enum ProductDiscoveryState: Equatable {

    /// No package environment is being inspected.
    case idle

    /// SwiftlyKit is preparing an environment or inspecting the package.
    case discovering(detail: String, installationTitle: String? = nil)

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

    /// Revision that requests another app-level discovery task.
    private(set) var retryRevision = 0

    /// Revision that requests presentation of the current installation approval.
    private(set) var installationApprovalRevision = 0

    /// Most recently discovered executable products.
    private(set) var availableProducts: [ExecutableProduct] = []

    /// Selected executable package product.
    var selectedProduct: ExecutableProduct?

    @ObservationIgnored private var preparedEnvironment: LocalBuildEnvironment?
    @ObservationIgnored private var preparedContext: Context?
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
                state = .installationRequired(approval)
                installationApprovalRevision += 1
                return
            }

            pendingInstallationContext = nil
            state = .discovering(
                detail: "Preparing Swift \(assessment.swiftVersion) for product discovery."
            )

            let environment = try await swiftlyKit.prepare(
                assessment,
                onEvent: { [weak self] event in
                    guard case .progress(let progress) = event else { return }
                    await self?.report(progress, swiftVersion: assessment.swiftVersion)
                }
            )

            lastPreparedContext = context
            state = .discovering(detail: "Inspecting executable package products.")

            let products = try await swiftlyKit.executableProducts(using: environment)

            guard !Task.isCancelled else { return }

            preparedEnvironment = environment
            preparedContext = context
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

    /// Requests presentation of the current installation approval.
    func requestInstallationApproval() {
        guard case .installationRequired = state else { return }
        installationApprovalRevision += 1
    }

    /// Returns the prepared environment and selection for one matching package configuration.
    func preparedPackage(
        in packageRoot: URL,
        for target: BuildTarget,
        toolchain: ToolchainSelection
    ) -> PreparedPackage? {
        let context = Context(
            packageRoot: packageRoot,
            target: target,
            toolchain: toolchain
        )

        guard case .ready = state else { return nil }
        guard preparedContext == context else { return nil }
        guard let preparedEnvironment else { return nil }
        guard let selectedProduct, availableProducts.contains(selectedProduct) else { return nil }

        return PreparedPackage(
            environment: preparedEnvironment,
            selectedProduct: selectedProduct
        )
    }

    /// Approves the pending installation and resumes product discovery.
    func approveInstallation() {
        guard let pendingInstallationContext else { return }

        approvedInstallationContext = pendingInstallationContext
        self.pendingInstallationContext = nil
        installationCancellationSnapshot = nil
        retryRevision += 1
    }

    /// Declines the pending installation and returns the last prepared toolchain when possible.
    func cancelInstallation() -> ToolchainSelection? {
        guard let pendingInstallationContext else { return nil }

        let cancellationSnapshot = installationCancellationSnapshot
        installationCancellationSnapshot = nil

        guard
            let lastPreparedContext,
            lastPreparedContext.packageRoot == pendingInstallationContext.packageRoot,
            lastPreparedContext.target == pendingInstallationContext.target,
            lastPreparedContext.toolchain != pendingInstallationContext.toolchain
        else {
            return nil
        }

        self.pendingInstallationContext = nil
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

    /// Replaces discovered products and keeps the selected product if its name remains available.
    func replaceProducts(with products: [ExecutableProduct]) {
        availableProducts = products
        selectedProduct = products.first { $0.name == selectedProduct?.name } ?? products.first
        state = products.isEmpty ? .empty : .ready
    }

}

extension ProductDiscovery {

    private func report(_ progress: OperationProgress, swiftVersion: SwiftVersion) {
        guard case .discovering = state else { return }
        guard case .preparingEnvironment(let component, _) = progress.operation else { return }

        switch component {
            case .swiftly:
                state = .discovering(
                    detail: "Setting up the Swift toolchain manager.",
                    installationTitle: "Installing Swiftly"
                )
            case .swiftlyUpdate:
                state = .discovering(
                    detail: "Checking for and applying an available update.",
                    installationTitle: "Updating Swiftly"
                )
            case .toolchain:
                state = .discovering(
                    detail: "Downloading and installing the toolchain. This may take a few minutes.",
                    installationTitle: "Installing Swift \(swiftVersion)"
                )
            case .staticLinuxSDK:
                state = .discovering(
                    detail: "Downloading and installing the SDK for Swift \(swiftVersion).",
                    installationTitle: "Installing Linux SDK"
                )
        }
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
        preparedEnvironment = nil
        preparedContext = nil
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
