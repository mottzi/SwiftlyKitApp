import SwiftUI

struct AppToolbar: ToolbarContent {
    
    @Environment(PackageModel.self) private var packageModel

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            HStack(spacing: 8) {
                if packageModel.isPackageSelected {
                    ClearPackageButton()
                }
                RunButton()
            }
            .labelStyle(.iconOnly)
        }
    }
    
}

struct ClearPackageButton: View {

    @Environment(PackageModel.self) private var packageModel

    var body: some View {
        Button {
            withAnimation {
                packageModel.clearPackage()
            }
        } label: {
            Label("Clear Package", systemImage: "trash.fill")
        }
    }
    
}

struct RunButton: View {

    @Environment(PackageModel.self) private var packageModel
    @Environment(BuildOptions.self) private var buildOptions

    private var canRun: Bool {
        packageModel.isPackageSelected && buildOptions.selectedProduct != nil
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
