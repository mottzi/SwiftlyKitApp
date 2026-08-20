import SwiftUI
import SwiftlyKit

struct ContentView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    PackageSelector()
                        .containerRelativeFrame(.horizontal)
                        .id(PackagePage.selector)
                    PackageView()
                        .containerRelativeFrame(.horizontal)
                        .id(PackagePage.project)
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $appState.packagePage)
            .scrollTargetBehavior(.viewAligned)
            .scrollDisabled(true)
            .scrollIndicators(.hidden)
            .safeAreaPadding(.horizontal)
            .frame(maxHeight: .infinity)

            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .toolbar {
            if appState.isPackageSelected {
                ToolbarItem {
                    Button {
                        withAnimation {
                            appState.clearPackage()
                        }
                    } label: {
                        Label("Clear Package", systemImage: "trash.fill")
                    }
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // action
                } label: {
                    Label("Run", systemImage: "play.fill")
                }
                .tint(appState.isPackageSelected ? .blue : nil)
                .disabled(!appState.isPackageSelected)
            }
        }
    }

}

#Preview {
    ContentView()
        .environment(AppState())
        .frame(width: 500, height: 300)
}

