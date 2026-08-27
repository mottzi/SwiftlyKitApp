import SwiftUI

struct AppView: View {

    @State private var packageModel = PackageModel()
    @State private var buildOptions = BuildOptions()

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
        .animation(.default, value: packageModel.isPackageSelected)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .onChange(of: packageModel.packageURL) {
            buildOptions.selectedProduct = nil
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
