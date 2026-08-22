import SwiftUI

struct PackageSection: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        PackageBuildDetails()
            .fixedSize(horizontal: false, vertical: true)
            .hidden()
            .frame(maxWidth: .infinity)
            .overlay {
                ZStack {
                    if appState.isPackageSelected {
                        PackageBuildDetails()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal)
                            .geometryGroup()
                            .transition(.move(edge: .trailing))
                    } else {
                        PackagePicker()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal)
                            .geometryGroup()
                            .transition(.move(edge: .leading))
                    }
                }
                .clipped()
            }
    }
}

#Preview {
    PackageSection()
        .environment(AppState())
        .frame(width: 500, height: 300)
}
