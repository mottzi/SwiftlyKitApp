import SwiftUI

struct AppView: View {

    @State private var packageModel = PackageModel()
    @State private var buildOptions = BuildOptions()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PackageSection()
                .padding(.horizontal, 12)
                .clipped()
                .fixedSize(horizontal: false, vertical: true)

            BuildSection()
                .padding(.horizontal, 12)
        }
        .debug()
        .padding(.bottom, 12)
        .padding(.top, 2)
        .toolbar { AppToolbar() }
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
        .frame(width: 500, height: 300)
}
