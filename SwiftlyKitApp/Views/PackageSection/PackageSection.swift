import SwiftUI

struct PackageSection: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        PagingHStack(selection: appState.packagePage) {
            PackagePicker()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()

            PackageBuildDetails()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
        .clipped()
    }
}

#Preview {
    PackageSection()
        .environment(AppState())
        .frame(width: 500, height: 300)
}
