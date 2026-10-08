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

    /// The root manifest supplied executable products; dependencies will be validated when building.
    case configured

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
    @ObservationIgnored private var pendingAssessment: EnvironmentAssessment?
    @ObservationIgnored private var approvedInstallationVersion: SwiftVersion?
    @ObservationIgnored private var lastPreparedContext: Context?
    @ObservationIgnored private var installationCancellationSnapshot: Snapshot?
    @ObservationIgnored private var contextToSkip: Context?
    @ObservationIgnored private var discoveryID = UUID()
    private let operations: PackageDiscoveryOperations

    init(swiftlyKit: SwiftlyKit) {
        operations = PackageDiscoveryOperations(swiftlyKit: swiftlyKit)
    }

    init(operations: PackageDiscoveryOperations) {
        self.operations = operations
    }

    /// Prepares the selected environment and discovers its executable products.
    func discover(
        in packageRoot: URL,
        for target: BuildTarget,
        toolchain: ToolchainSelection,
        environmentChoices: EnvironmentChoices
    ) async {
        let discoveryID = UUID()
        self.discoveryID = discoveryID
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
            var assessment: EnvironmentAssessment
            if pendingInstallationContext == context, let pendingAssessment {
                assessment = pendingAssessment
            } else {
                assessment = try environmentChoices.select(toolchain)
            }
            while true {

                if assessment.requiresInstallation,
                   approvedInstallationContext != context || approvedInstallationVersion != assessment.swiftVersion {
                    guard isCurrent(discoveryID) else { return }

                    let approval = InstallationApprovalRequest(
                        swiftVersion: assessment.swiftVersion,
                        staticLinuxSDKVersion: assessment.staticLinuxSDK.version,
                        requiredComponents: assessment.requiredComponents
                    )
                    installationCancellationSnapshot = cancellationSnapshot()
                    pendingInstallationContext = context
                    pendingAssessment = assessment
                    state = .installationRequired(approval)
                    installationApprovalRevision += 1
                    return
                }

                pendingInstallationContext = nil
                pendingAssessment = nil
                state = .discovering(
                    detail: "Preparing Swift \(assessment.swiftVersion) for product discovery."
                )

                let swiftVersion = assessment.swiftVersion
                let environment = try await operations.prepare(
                    assessment,
                    { [weak self] event in
                        guard case .progress(let progress) = event else { return }
                        await self?.report(progress, swiftVersion: swiftVersion, discoveryID: discoveryID)
                    }
                )

                guard isCurrent(discoveryID) else { return }
                state = .discovering(detail: "Inspecting executable package products.")

                let configuration: PackageConfiguration
                do {
                    configuration = try await operations.configure(
                        environment,
                        { [weak self] event in
                            guard case .progress(let progress) = event else { return }
                            await self?.report(progress, swiftVersion: swiftVersion, discoveryID: discoveryID)
                        }
                    )
                } catch let error as SwiftlyKitError {
                    guard isCurrent(discoveryID) else { return }
                    guard let recovery = environmentChoices.recoveryAssessment(after: error, for: toolchain)
                    else { throw error }
                    assessment = recovery
                    continue
                }

                guard isCurrent(discoveryID) else { return }

                lastPreparedContext = context
                preparedEnvironment = configuration.environment
                preparedContext = context
                replaceProducts(with: Array(configuration.products))
                break
            }
        } catch is CancellationError {
            // a replacement task owns the next state transition
        } catch let error as SwiftlyKitError {
            guard isCurrent(discoveryID) else { return }
            state = .failed(error)
        } catch {
            guard isCurrent(discoveryID) else { return }
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
    func preparedPackage(in packageRoot: URL, for target: BuildTarget, toolchain: ToolchainSelection) -> PreparedPackage? {
        let context = Context(
            packageRoot: packageRoot,
            target: target,
            toolchain: toolchain
        )

        guard case .configured = state else { return nil }
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
        approvedInstallationVersion = pendingAssessment?.swiftVersion
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
        else { return nil }

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
        discoveryID = UUID()
        state = .idle
        availableProducts = []
        selectedProduct = nil
        resetContext()
    }

    /// Invalidates discovery while a replacement result is prepared.
    func invalidate() {
        discoveryID = UUID()
        state = .idle
        resetContext()
    }

    /// Replaces discovered products and keeps the selected product if its name remains available.
    func replaceProducts(with products: [ExecutableProduct]) {
        availableProducts = products
        selectedProduct = products.first { $0.name == selectedProduct?.name } ?? products.first
        state = products.isEmpty ? .empty : .configured
    }

}

extension ProductDiscovery {

    private func isCurrent(_ discoveryID: UUID) -> Bool {
        self.discoveryID == discoveryID && !Task.isCancelled
    }

    private func cancellationSnapshot() -> Snapshot? {
        guard let lastPreparedContext else { return nil }

        switch state {
            case .configured, .empty, .failed:
                return Snapshot(
                    context: lastPreparedContext,
                    state: state,
                    selectedProduct: selectedProduct
                )
            case .idle, .discovering, .installationRequired:
                return nil
        }
    }

    private func report(_ progress: OperationProgress, swiftVersion: SwiftVersion, discoveryID: UUID) {
        guard isCurrent(discoveryID) else { return }
        guard case .discovering = state else { return }
        if progress.operation == .inspectingPackage || progress.operation == .resolvingDependencies {
            state = .discovering(detail: progress.detail)
            return
        }
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

    private func resetContext() {
        preparedEnvironment = nil
        preparedContext = nil
        pendingInstallationContext = nil
        approvedInstallationContext = nil
        approvedInstallationVersion = nil
        pendingAssessment = nil
        lastPreparedContext = nil
        installationCancellationSnapshot = nil
        contextToSkip = nil
    }

}

extension ProductDiscovery {

    /// Package configuration that owns a prepared environment or installation approval.
    private struct Context: Equatable {
        let packageRoot: URL
        let target: BuildTarget
        let toolchain: ToolchainSelection
    }

    /// Discovery state restored if the user cancels installation for another toolchain.
    private struct Snapshot {
        let context: Context
        let state: ProductDiscoveryState
        let selectedProduct: ExecutableProduct?
    }

}
