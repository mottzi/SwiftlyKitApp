import SwiftlyKit
import SwiftUI

struct AppView: View {

    @State private var packageModel = PackageModel()
    @State private var buildOptions = BuildOptions()

    private struct ProductDiscoveryKey: Hashable, Sendable {
        let packageRoot: URL
        let target: BuildTarget
        let toolchain: ToolchainSelection
    }

    private var productDiscoveryKey: ProductDiscoveryKey? {
        guard let packageRoot = packageModel.packageURL else { return nil }

        return ProductDiscoveryKey(
            packageRoot: packageRoot,
            target: buildOptions.target,
            toolchain: buildOptions.toolchain
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.appSpacing) {
            PackageSection()
                .padding(.horizontal, Constants.appHorizontalPadding)
                .clipped()
                .fixedSize(horizontal: false, vertical: true)
                .windowMinimumHeight(adding: Constants.windowHeightAllowance)

            BuildSection()
                .padding(.horizontal, Constants.appHorizontalPadding)
        }
        .frame(minWidth: Constants.minWindowWidth)
        .padding(.bottom, Constants.appBottomPadding)
        .padding(.top, Constants.appTopPadding)
        .toolbar { AppToolbar() }
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
            width: Constants.windowSize.width,
            height: Constants.windowSize.height
        )
}
