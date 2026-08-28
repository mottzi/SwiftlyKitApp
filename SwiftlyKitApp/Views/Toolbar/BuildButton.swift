import SwiftUI

struct BuildButton: View {

    @Environment(PackageModel.self) private var packageModel
    @Environment(BuildOptions.self) private var buildOptions

    private var canBuild: Bool {
        packageModel.isPackageSelected && buildOptions.hasValidSelections
    }

    var body: some View {
        buildButton
    }

    @ViewBuilder
    private var buildButton: some View {
//        if #available(macOS 26.0, *) {
        Button {
            // action
        } label: {
            Label("Build", systemImage: "hammer.fill")
                .padding(4)
        }
        .labelStyle(.iconOnly)
//        .tint(canBuild ? .blue : nil)
        .disabled(!canBuild)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
//        } else {
//            button
//                .buttonStyle(.glassProminent)
//        }
    }

}
