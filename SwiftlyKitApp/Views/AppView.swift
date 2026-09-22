import SwiftUI

/// Package configuration and build output with shared state for one window.
struct AppView: View {

    @State private var packageModel = PackageModel()
    @State private var buildOptions = BuildOptions()

    var body: some View {
        VStack(alignment: .leading, spacing: Self.spacing) {
            PackageSection()
                .padding(.horizontal, Self.horizontalPadding)
                .clipped()
                .fixedSize(horizontal: false, vertical: true)
                .windowMinimumSize(addingHeight: Self.minimumHeightOutsidePackageSection)

            BuildSection()
                .padding(.horizontal, Self.horizontalPadding)
        }
        .frame(minWidth: Self.minWindowWidth)
        .padding(.bottom, Self.bottomPadding)
        .padding(.top, Self.topPadding)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .managesPackageDiscovery(
            packageModel: packageModel,
            buildOptions: buildOptions
        )
        .environment(packageModel)
        .environment(buildOptions)
    }

}

extension AppView {

    private static let spacing: CGFloat = 10
    private static let horizontalPadding: CGFloat = 12
    private static let topPadding: CGFloat = 4
    private static let bottomPadding: CGFloat = 12
    private static let minWindowWidth: CGFloat = 300
    private static let minimumHeightOutsidePackageSection =
        topPadding + spacing + BuildSection.minimumHeight + bottomPadding

}
