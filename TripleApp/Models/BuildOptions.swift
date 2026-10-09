import Foundation
import Observation
import OSLog
import Triple

@Observable
/// Build choices and the discovery workflows that keep them valid.
final class BuildOptions {

    let hostDiscovery: HostDiscovery
    let toolchainDiscovery: ToolchainDiscovery
    let productDiscovery: ProductDiscovery
    let buildWorkflow: BuildWorkflow
    let buildStorageMaintenance: BuildStorageMaintenance

    /// Selected cross-compilation target.
    var target: BuildTarget = .linux(.x86_64)

    /// Selected SwiftPM build configuration.
    var configuration: BuildConfiguration = .release

    /// Selected Swift toolchain policy.
    var toolchain: ToolchainSelection = .automatic

    /// Whether the strip-binary toggle is enabled.
    var stripBinary = false

    private let activity: AppActivity

    @ObservationIgnored private var discoveryID = UUID()
    @ObservationIgnored private var discoveryPackage: URL?
    @ObservationIgnored private var discoveredHostRevision = -1
    @ObservationIgnored private var discoveredToolchainRevision = -1

    init(triple: Triple = Triple(), activity: AppActivity = AppActivity()) {
        self.activity = activity
        let operations = PackageDiscoveryOperations(triple: triple)
        hostDiscovery = HostDiscovery(readiness: operations.hostReadiness, activity: activity)
        toolchainDiscovery = ToolchainDiscovery(compatibleEnvironments: operations.compatibleEnvironments)
        productDiscovery = ProductDiscovery(operations: operations)
        buildWorkflow = BuildWorkflow(triple: triple, activity: activity)
        buildStorageMaintenance = BuildStorageMaintenance(triple: triple, activity: activity)
    }

    init(
        discoveryOperations: PackageDiscoveryOperations,
        triple: Triple = Triple(),
        activity: AppActivity = AppActivity()
    ) {
        self.activity = activity
        hostDiscovery = HostDiscovery(readiness: discoveryOperations.hostReadiness, activity: activity)
        toolchainDiscovery = ToolchainDiscovery(compatibleEnvironments: discoveryOperations.compatibleEnvironments)
        productDiscovery = ProductDiscovery(operations: discoveryOperations)
        buildWorkflow = BuildWorkflow(triple: triple, activity: activity)
        buildStorageMaintenance = BuildStorageMaintenance(triple: triple, activity: activity)
    }

    /// Owns the ordered discovery stages for one selected package and set of choices.
    func discoverPackage(in packageRoot: URL, for target: BuildTarget, toolchain: ToolchainSelection) async {

        let operation = activity.beginOperation()
        defer { activity.endOperation(operation) }

        let discoveryID = UUID()
        self.discoveryID = discoveryID
        self.toolchain = toolchain
        let clock = ContinuousClock()
        let started = clock.now
        let hostRevision = hostDiscovery.retryRevision
        let toolchainRevision = toolchainDiscovery.retryRevision

        if discoveryPackage != packageRoot || discoveredHostRevision != hostRevision {
            discoveryPackage = packageRoot
            await discoverHost()
            guard isCurrent(discoveryID) else { return }
            discoveredHostRevision = hostRevision
            Self.logger.info(
                "Host discovery finished after \(started.duration(to: clock.now).description, privacy: .public)"
            )
        }
        guard case .ready = hostDiscovery.state else { return }

        if !hasDiscoveredToolchains(in: packageRoot, for: target)
            || discoveredToolchainRevision != toolchainRevision {
            productDiscovery.invalidate()
            let selected = await toolchainDiscovery.discover(
                in: packageRoot,
                for: target,
                selectedToolchain: toolchain
            )
            guard isCurrent(discoveryID) else { return }
            guard let selected else { return }
            self.toolchain = selected
            discoveredToolchainRevision = toolchainRevision
            Self.logger.info(
                "Swift choices finished after \(started.duration(to: clock.now).description, privacy: .public)"
            )
        }
        guard isCurrent(discoveryID) else { return }
        await discoverProducts(in: packageRoot, for: target, toolchain: self.toolchain)
        guard isCurrent(discoveryID) else { return }
        Self.logger.info(
            "Package configuration finished after \(started.duration(to: clock.now).description, privacy: .public)"
        )
    }

    /// Whether a build, export, or build-storage operation owns the package environment.
    var isOperationRunning: Bool {
        buildWorkflow.isRunning || buildStorageMaintenance.isRunning
    }

    /// Whether package selection has given the discovery workflow a package session to discard.
    var hasPackageSession: Bool { discoveryPackage != nil }

    /// Keeps configuration controls still during I/O, while retaining actions for setup failures and approvals.
    func canEditConfiguration(for packageModel: PackageModel) -> Bool {
        guard packageModel.isConfigurationReady else { return false }
        guard !isOperationRunning else { return false }
        if case .checking = hostDiscovery.state { return false }
        if case .discovering = toolchainDiscovery.state { return false }
        if case .discovering = productDiscovery.state { return false }
        return true
    }

    /// Allows the visible Build action after the page transition and root configuration both finish.
    func canStartBuild(for packageModel: PackageModel) -> Bool {
        guard packageModel.isConfigurationReady else { return false }
        guard !isOperationRunning else { return false }
        guard let packageRoot = packageModel.packageURL else { return false }
        return preparedPackage(in: packageRoot) != nil
    }

    /// Uses the same presentation and configuration requirements as the Build button.
    func startBuild(for packageModel: PackageModel) {
        guard canStartBuild(for: packageModel) else { return }
        guard let packageRoot = packageModel.packageURL else { return }
        startBuild(in: packageRoot)
    }

    /// Starts a build from the prepared package and a snapshot of the current build choices.
    func startBuild(in packageRoot: URL) {
        guard !buildStorageMaintenance.isRunning else { return }
        guard let preparedPackage = preparedPackage(in: packageRoot) else { return }

        buildWorkflow.start(
            preparedPackage,
            target: target,
            configuration: configuration,
            stripBinary: stripBinary,
            environmentChoices: toolchainDiscovery.environmentChoices(in: packageRoot, for: target),
            toolchain: toolchain
        )
    }

    /// Performs cleanup for the selected package's prepared environment.
    func performCleanup(_ cleanup: BuildStorageCleanup, in packageRoot: URL) async throws {
        guard !buildWorkflow.isRunning else { return }
        guard let preparedPackage = preparedPackage(in: packageRoot) else { return }

        buildWorkflow.discardSession()
        try await buildStorageMaintenance.perform(
            cleanup,
            using: preparedPackage.environment
        )
    }

    /// Returns a prepared package only if it matches every current discovery choice.
    func preparedPackage(in packageRoot: URL) -> PreparedPackage? {
        productDiscovery.preparedPackage(
            in: packageRoot,
            for: target,
            toolchain: toolchain
        )
    }

    /// Inspects host readiness before package environment discovery begins.
    func discoverHost() async {
        clearEnvironmentDiscoveries(resetToolchain: false)
        await hostDiscovery.inspect()
    }

    /// Whether successful toolchain discovery belongs to the supplied package and target.
    func hasDiscoveredToolchains(in packageRoot: URL, for target: BuildTarget) -> Bool {
        toolchainDiscovery.hasResults(in: packageRoot, for: target)
    }

    /// Discovers compatible Swift releases and reconciles the selected toolchain.
    func discoverToolchains(in packageRoot: URL, for target: BuildTarget) async {
        productDiscovery.invalidate()

        guard let toolchain = await toolchainDiscovery.discover(
            in: packageRoot,
            for: target,
            selectedToolchain: toolchain
        ) else { return }

        self.toolchain = toolchain
    }

    /// Prepares the selected discovered environment and discovers its executable products.
    func discoverProducts(
        in packageRoot: URL,
        for target: BuildTarget,
        toolchain selectedToolchain: ToolchainSelection
    ) async {
        guard let environmentChoices = toolchainDiscovery.environmentChoices(
            in: packageRoot,
            for: target
        ) else {
            productDiscovery.invalidate()
            return
        }

        await productDiscovery.discover(
            in: packageRoot,
            for: target,
            toolchain: selectedToolchain,
            environmentChoices: environmentChoices
        )
    }

    /// Declines the pending installation and restores the last prepared toolchain when possible.
    func cancelInstallation() {
        guard let toolchain = productDiscovery.cancelInstallation() else { return }
        self.toolchain = toolchain
    }

    /// Discards state owned by the selected package while preserving build preferences.
    func clearPackageSession() {
        guard !buildStorageMaintenance.isRunning else { return }
        guard !buildWorkflow.isExporting else { return }

        discoveryID = UUID()
        discoveryPackage = nil
        discoveredHostRevision = -1
        discoveredToolchainRevision = -1

        buildWorkflow.cancel()
        buildWorkflow.discardSession()
        hostDiscovery.clear()
        clearEnvironmentDiscoveries()
    }

}

extension BuildOptions {

    private func isCurrent(_ discoveryID: UUID) -> Bool {
        self.discoveryID == discoveryID && !Task.isCancelled
    }

    /// Clears package environment discoveries but preserves current host readiness.
    func clearEnvironmentDiscoveries(resetToolchain: Bool = true) {
        toolchainDiscovery.clear()
        productDiscovery.clear()
        if resetToolchain { toolchain = .automatic }
    }

    private static let logger = Logger(subsystem: "codes.mottzi.SwiftlyKitApp", category: "PackageDiscovery")

}
