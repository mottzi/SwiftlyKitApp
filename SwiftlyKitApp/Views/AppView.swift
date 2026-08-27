import SwiftUI

struct AppView: View {

    @State private var packageModel = PackageModel()
    @State private var buildOptions = BuildOptions()

    /// Natural package height reported by the active layout.
    @State private var packageSectionHeight: CGFloat?

    private var minimumContentHeight: CGFloat? {
        packageSectionHeight.map { $0 + 10 + 80 + 14 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PackageSection()
                .padding(.horizontal, 12)
                .clipped()
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { geometry in
                    geometry.size.height
                } action: { height in
                    guard height.isFinite, height > 0 else { return }
                    packageSectionHeight = height
                }

            BuildSection()
                .padding(.horizontal, 12)
        }
        .frame(minWidth: 300)
        .padding(.bottom, 12)
        .padding(.top, 2)
        .toolbar { AppToolbar() }
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .onChange(of: packageModel.packageURL) {
            buildOptions.selectedProduct = nil
        }
        .environment(packageModel)
        .environment(buildOptions)
        .background {
            if let minimumContentHeight {
                WindowMinimumSizeBridge(minimumHeight: minimumContentHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
}

#Preview {
    AppView()
        .frame(width: 500, height: 300)
}
