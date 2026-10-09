import Triple
import SwiftUI

extension View {

    /// Runs package discovery tasks and presents installation approval for the supplied models.
    func managesPackageDiscovery(packageModel: PackageModel, buildOptions: BuildOptions) -> some View {
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

/// Gives one task ownership of discovery for the selected package configuration.
private struct PackageDiscoveryModifier: ViewModifier {

    let packageModel: PackageModel
    let buildOptions: BuildOptions

    func body(content: Content) -> some View {
        let discoveryKey = discoveryKey
        return content
            .task(id: discoveryKey) {
                guard !Task.isCancelled else { return }
                guard let discoveryKey else {
                    guard packageModel.packageURL == nil else { return }
                    if buildOptions.hasPackageSession { buildOptions.clearPackageSession() }
                    return
                }

                await buildOptions.discoverPackage(
                    in: discoveryKey.packageRoot,
                    for: discoveryKey.target,
                    toolchain: discoveryKey.toolchain
                )
            }
    }

}

extension PackageDiscoveryModifier {

    private var discoveryKey: DiscoveryKey? {
        guard let packageRoot = packageModel.packageURL else { return nil }

        return DiscoveryKey(
            packageRoot: packageRoot,
            target: buildOptions.target,
            toolchain: buildOptions.toolchain,
            hostRetryRevision: buildOptions.hostDiscovery.retryRevision,
            toolchainRetryRevision: buildOptions.toolchainDiscovery.retryRevision,
            productRetryRevision: buildOptions.productDiscovery.retryRevision
        )
    }

    /// All inputs that replace discovery work; intermediate results do not schedule extra tasks.
    private struct DiscoveryKey: Equatable {
        let packageRoot: URL
        let target: BuildTarget
        let toolchain: ToolchainSelection
        let hostRetryRevision: Int
        let toolchainRetryRevision: Int
        let productRetryRevision: Int
    }

}
