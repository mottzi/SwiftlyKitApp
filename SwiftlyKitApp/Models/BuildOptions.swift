import Foundation
import Observation
import SwiftlyKit

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

    init(swiftlyKit: SwiftlyKit = SwiftlyKit()) {
        hostDiscovery = HostDiscovery()
        toolchainDiscovery = ToolchainDiscovery(swiftlyKit: swiftlyKit)
        productDiscovery = ProductDiscovery(swiftlyKit: swiftlyKit)
        buildWorkflow = BuildWorkflow(swiftlyKit: swiftlyKit)
        buildStorageMaintenance = BuildStorageMaintenance(swiftlyKit: swiftlyKit)
    }

    /// Whether a build, publication, or build-storage operation owns the package environment.
    var isOperationRunning: Bool {
        buildWorkflow.isRunning || buildStorageMaintenance.isRunning
    }

    /// Starts a build from the prepared package and a snapshot of the current build choices.
    func startBuild(in packageRoot: URL) {
        guard !buildStorageMaintenance.isRunning else { return }
        guard let preparedPackage = preparedPackage(in: packageRoot) else { return }

        buildWorkflow.start(
            preparedPackage,
            target: target,
            configuration: configuration,
            stripBinary: stripBinary
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
        clearEnvironmentDiscoveries()
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
        guard !buildWorkflow.isPublishing else { return }

        buildWorkflow.cancel()
        buildWorkflow.discardSession()
        hostDiscovery.clear()
        clearEnvironmentDiscoveries()
    }

}

extension BuildOptions {

    /// Clears package environment discoveries but preserves current host readiness.
    func clearEnvironmentDiscoveries() {
        toolchainDiscovery.clear()
        productDiscovery.clear()
        toolchain = .automatic
    }

}
