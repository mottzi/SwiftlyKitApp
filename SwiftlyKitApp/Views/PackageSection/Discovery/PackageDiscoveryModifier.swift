import SwiftlyKit
import SwiftUI

extension View {

    /// Runs package discovery tasks and presents installation approval for the supplied models.
    func managesPackageDiscovery(
        packageModel: PackageModel,
        buildOptions: BuildOptions
    ) -> some View {
        modifier(
            PackageDiscoveryModifier(
                packageModel: packageModel,
                buildOptions: buildOptions
            )
        )
        .modifier(
            PackageDiscoveryApprovalModifier(buildOptions: buildOptions)
        )
    }

}

/// Schedules host, toolchain, and product discovery for the selected package.
private struct PackageDiscoveryModifier: ViewModifier {

    let packageModel: PackageModel
    let buildOptions: BuildOptions

    func body(content: Content) -> some View {
        content
            .task(id: hostDiscoveryKey) {
                guard hostDiscoveryKey != nil else {
                    buildOptions.clearPackageSession()
                    return
                }

                await buildOptions.discoverHost()
            }
            .task(id: toolchainDiscoveryKey) {
                guard let toolchainDiscoveryKey else {
                    buildOptions.clearEnvironmentDiscoveries()
                    return
                }

                await buildOptions.discoverToolchains(
                    in: toolchainDiscoveryKey.packageRoot,
                    for: toolchainDiscoveryKey.target
                )
            }
            .task(id: productDiscoveryKey) {
                guard let productDiscoveryKey else { return }

                await buildOptions.discoverProducts(
                    in: productDiscoveryKey.packageRoot,
                    for: productDiscoveryKey.target,
                    toolchain: productDiscoveryKey.toolchain
                )
            }
    }

}

extension PackageDiscoveryModifier {

    /// Identifies one selected package, completed page transition, or explicit host retry request.
    private struct HostDiscoveryKey: Equatable {
        let packageRoot: URL
        let retryRevision: Int
    }

    private var hostDiscoveryKey: HostDiscoveryKey? {
        guard packageModel.isConfigurationReady else { return nil }
        guard let packageRoot = packageModel.packageURL else { return nil }

        return HostDiscoveryKey(
            packageRoot: packageRoot,
            retryRevision: buildOptions.hostDiscovery.retryRevision
        )
    }

}

extension PackageDiscoveryModifier {

    /// Identifies one package, target, or explicit toolchain retry request.
    private struct ToolchainDiscoveryKey: Equatable {
        let packageRoot: URL
        let target: BuildTarget
        let retryRevision: Int
    }

    private var toolchainDiscoveryKey: ToolchainDiscoveryKey? {
        guard case .ready = buildOptions.hostDiscovery.state else { return nil }
        guard let packageRoot = packageModel.packageURL else { return nil }

        return ToolchainDiscoveryKey(
            packageRoot: packageRoot,
            target: buildOptions.target,
            retryRevision: buildOptions.toolchainDiscovery.retryRevision
        )
    }

}

extension PackageDiscoveryModifier {

    /// Identifies one package, environment, or explicit product retry request.
    private struct ProductDiscoveryKey: Equatable {
        let packageRoot: URL
        let target: BuildTarget
        let toolchain: ToolchainSelection
        let toolchainDiscoveryRevision: Int
        let productDiscoveryRetryRevision: Int
    }

    private var productDiscoveryKey: ProductDiscoveryKey? {
        guard let packageRoot = packageModel.packageURL else { return nil }
        guard buildOptions.hasDiscoveredToolchains(
            in: packageRoot,
            for: buildOptions.target
        ) else { return nil }

        return ProductDiscoveryKey(
            packageRoot: packageRoot,
            target: buildOptions.target,
            toolchain: buildOptions.toolchain,
            toolchainDiscoveryRevision: buildOptions.toolchainDiscovery.revision,
            productDiscoveryRetryRevision: buildOptions.productDiscovery.retryRevision
        )
    }

}
