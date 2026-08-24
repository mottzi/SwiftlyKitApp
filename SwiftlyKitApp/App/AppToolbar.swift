import SwiftUI

struct AppToolbar: ToolbarContent {
    
    @Environment(PackageModel.self) private var packageModel

    var body: some ToolbarContent {
        if packageModel.isPackageSelected {
            ToolbarItem {
                ClearPackageButton()
            }
        }

        ToolbarItem(placement: .primaryAction) {
            RunButton()
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

    var body: some View {
        Button {
            // action
        } label: {
            Label("Run", systemImage: "play.fill")
        }
        .tint(packageModel.isPackageSelected ? .blue : nil)
        .disabled(!packageModel.isPackageSelected)
    }
    
}
