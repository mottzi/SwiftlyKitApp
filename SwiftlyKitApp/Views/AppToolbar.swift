import SwiftUI

struct AppToolbar: ToolbarContent {
    
    @Environment(PackageModel.self) private var packageModel

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            RunButton()
                .labelStyle(.iconOnly)
        }
    }
    
}

struct RunButton: View {

    @Environment(PackageModel.self) private var packageModel
    @Environment(BuildOptions.self) private var buildOptions

    private var canRun: Bool {
        packageModel.isPackageSelected && buildOptions.hasValidSelections
    }

    var body: some View {
        Button {
            // action
        } label: {
            Label("Run", systemImage: "play.fill")
        }
        .tint(canRun ? .blue : nil)
        .disabled(!canRun)
    }
    
}
