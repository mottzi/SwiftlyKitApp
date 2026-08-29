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
    }

}

/// Coordinates toolchain discovery, product discovery, and installation approval.
private struct PackageDiscoveryModifier: ViewModifier {

    @State private var installationApprovalPresented = false

    let packageModel: PackageModel
    let buildOptions: BuildOptions

    func body(content: Content) -> some View {
        content
            .task(id: toolchainDiscoveryKey) {
                guard let toolchainDiscoveryKey else {
                    buildOptions.clearDiscoveries()
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
            .onChange(
                of: buildOptions.productDiscovery.installationApprovalRequest,
                initial: true
            ) {
                installationApprovalPresented = buildOptions.productDiscovery
                    .installationApprovalRequest != nil
            }
            .alert(
                "Install required tools?",
                isPresented: $installationApprovalPresented,
                presenting: buildOptions.productDiscovery.installationApprovalRequest
            ) { _ in
                Button("Install") {
                    buildOptions.productDiscovery.approveInstallation()
                }
                .keyboardShortcut(.defaultAction)

                Button("Cancel", role: .cancel) {
                    buildOptions.cancelInstallation()
                }
            } message: { approval in
                Text(approval.message)
            }
    }

}

extension PackageDiscoveryModifier {

    /// Identifies one package, target, or explicit toolchain retry request.
    private struct ToolchainDiscoveryKey: Equatable {
        let packageRoot: URL
        let target: BuildTarget
        let retryRevision: Int
    }

    ///
    private var toolchainDiscoveryKey: ToolchainDiscoveryKey? {
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

    ///
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
