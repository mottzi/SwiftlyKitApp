import SwiftlyKit
import SwiftUI

struct AppView: View {

    @State private var packageModel = PackageModel()
    @State private var buildOptions = BuildOptions()

    /// Identifies one package, environment, or explicit retry request.
    private struct ProductDiscoveryKey: Hashable, Sendable {
        let packageRoot: URL
        let target: BuildTarget
        let toolchain: ToolchainSelection
        let retryRevision: Int
    }

    private var productDiscoveryKey: ProductDiscoveryKey? {
        guard let packageRoot = packageModel.packageURL else { return nil }

        return ProductDiscoveryKey(
            packageRoot: packageRoot,
            target: buildOptions.target,
            toolchain: buildOptions.toolchain,
            retryRevision: buildOptions.productDiscoveryRetryRevision
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Self.spacing) {
            PackageSection()
                .padding(.horizontal, Self.horizontalPadding)
                .clipped()
                .fixedSize(horizontal: false, vertical: true)
                .windowMinimumSize(addingHeight: Self.windowHeightAllowance)

            BuildSection()
                .padding(.horizontal, Self.horizontalPadding)
        }
        .frame(minWidth: Self.minWindowWidth)
        .padding(.bottom, Self.bottomPadding)
        .padding(.top, Self.topPadding)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .task(id: productDiscoveryKey) {
            guard let productDiscoveryKey else {
                buildOptions.clearProducts()
                return
            }

            await buildOptions.discoverProducts(
                in: productDiscoveryKey.packageRoot,
                for: productDiscoveryKey.target,
                toolchain: productDiscoveryKey.toolchain
            )
        }
        .environment(packageModel)
        .environment(buildOptions)
    }
    
}

#Preview {
    AppView()
        .frame(
            width: SwiftlyKitApp.defaultWindowSize.width,
            height: SwiftlyKitApp.defaultWindowSize.height
        )
}

private extension AppView {

    static let spacing: CGFloat = 10
    static let horizontalPadding: CGFloat = 12
    static let topPadding: CGFloat = 2
    static let bottomPadding: CGFloat = 12
    static let minWindowWidth: CGFloat = 300
    static let windowHeightAllowance = spacing
        + BuildSectionMetrics.minimumHeight
        + topPadding
        + bottomPadding

}
