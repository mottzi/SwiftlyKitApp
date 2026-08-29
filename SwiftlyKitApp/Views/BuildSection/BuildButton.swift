import SwiftUI

struct BuildButton: View {

    @Environment(PackageModel.self) private var packageModel
    @Environment(BuildOptions.self) private var buildOptions

    private var canBuild: Bool {
        guard let packageRoot = packageModel.packageURL else { return false }
        return buildOptions.preparedPackage(in: packageRoot) != nil
    }

    var body: some View {
        Button {
            // action
        } label: {
            Label("Build", systemImage: "hammer.fill")
                .padding(4)
        }
        .labelStyle(.iconOnly)
        .disabled(!canBuild)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }

}
