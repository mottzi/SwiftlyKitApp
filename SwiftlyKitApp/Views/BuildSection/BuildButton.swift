import SwiftUI

struct BuildButton: View {

    @Environment(PackageModel.self) private var packageModel
    @Environment(BuildOptions.self) private var buildOptions

    var body: some View {
        Button(action: startBuild) {
            Label("Build", systemImage: "play.fill")
                .padding(4)
        }
        .labelStyle(.iconOnly)
        .disabled(!canBuild)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .keyboardShortcut("b", modifiers: .command)
        .help("Build the selected product (⌘B)")
    }

}

extension BuildButton {

    private var canBuild: Bool {
        buildOptions.canStartBuild(for: packageModel)
    }

    private func startBuild() {
        buildOptions.startBuild(for: packageModel)
    }

}
