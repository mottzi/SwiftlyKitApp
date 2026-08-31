import SwiftUI

struct BuildButton: View {

    @Environment(PackageModel.self) private var packageModel
    @Environment(BuildOptions.self) private var buildOptions

    var body: some View {
        Button(action: startBuild) {
            Label("Build", systemImage: "hammer.fill")
                .padding(4)
        }
        .labelStyle(.iconOnly)
        .disabled(!canBuild || buildOptions.isOperationRunning)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .keyboardShortcut("b", modifiers: .command)
        .help("Build the selected product (⌘B)")
    }

}

extension BuildButton {

    private var canBuild: Bool {
        guard let packageRoot = packageModel.packageURL else { return false }
        return buildOptions.preparedPackage(in: packageRoot) != nil
    }

    private func startBuild() {
        guard let packageRoot = packageModel.packageURL else { return }
        buildOptions.startBuild(in: packageRoot)
    }

}
