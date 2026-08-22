import SwiftUI

struct PackageSection: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                PackagePicker()
                    .containerRelativeFrame(.horizontal)
                    .frame(maxHeight: .infinity)
                    .id(PackagePage.selector)
                
                PackageBuildDetails()
                    .containerRelativeFrame(.horizontal)
                    .frame(maxHeight: .infinity)
                    .id(PackagePage.project)
            }
            .fixedSize(horizontal: false, vertical: true)
            .scrollTargetLayout()
        }
        .scrollPosition(id: $appState.packagePage)
        .scrollTargetBehavior(.viewAligned)
//        .scrollDisabled(true)
        .scrollClipDisabled(true)
        .scrollIndicators(.hidden)
        .safeAreaPadding(.horizontal)
    }
}

#Preview {
    PackageSection()
        .environment(AppState())
        .frame(width: 500, height: 300)
}
