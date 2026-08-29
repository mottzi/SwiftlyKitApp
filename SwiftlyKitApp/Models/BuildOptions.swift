import Foundation
import Observation
import SwiftlyKit

@Observable
/// Build choices and the discovery workflows that keep them valid.
final class BuildOptions {

    let toolchainDiscovery: ToolchainDiscovery
    let productDiscovery: ProductDiscovery

    /// Selected cross-compilation target.
    var target: BuildTarget = .linux(.x86_64)

    /// Selected SwiftPM build configuration.
    var configuration: BuildConfiguration = .release

    /// Selected Swift toolchain policy.
    var toolchain: ToolchainSelection = .automatic

    /// Whether the strip-binary toggle is enabled.
    var stripBinary = false

    init(swiftlyKit: SwiftlyKit = SwiftlyKit()) {
        toolchainDiscovery = ToolchainDiscovery(swiftlyKit: swiftlyKit)
        productDiscovery = ProductDiscovery(swiftlyKit: swiftlyKit)
    }

    /// Whether every required build choice has a valid selection.
    var hasValidSelections: Bool {
        productDiscovery.hasValidSelection
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

    /// Clears discoveries that belong to a package or target that is no longer selected.
    func clearDiscoveries() {
        toolchainDiscovery.clear()
        productDiscovery.clear()
        toolchain = .automatic
    }

}
