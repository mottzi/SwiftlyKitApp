import SwiftUI

struct AppView: View {

    @State private var packageModel = PackageModel()
    @State private var buildOptions = BuildOptions()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PackageSection()
            BuildSection()
        }
        .padding(.vertical)
        .toolbar { AppToolbar() }
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .environment(packageModel)
        .environment(buildOptions)
    }
    
}

#Preview {
    AppView()
        .frame(width: 500, height: 300)
}
