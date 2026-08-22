import SwiftUI

struct AppToolbar: ToolbarContent {
    
    @Environment(AppState.self) private var appState

    var body: some ToolbarContent {
        if appState.isPackageSelected {
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

    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            withAnimation {
                appState.clearPackage()
            }
        } label: {
            Label("Clear Package", systemImage: "trash.fill")
        }
    }
}

struct RunButton: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            // action
        } label: {
            Label("Run", systemImage: "play.fill")
        }
        .tint(appState.isPackageSelected ? .blue : nil)
        .disabled(!appState.isPackageSelected)
    }
}
