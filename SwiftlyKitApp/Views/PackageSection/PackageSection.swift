import SwiftUI

struct PackageSection: View {

    @Environment(PackageModel.self) private var packageModel

    var body: some View {
        PagingHStack(selection: packageModel.packagePage) {
            PackagePicker()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()

            PackageBuildDetails()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 8)
        .clipped()
    }
}

#Preview {
    PackageSection()
        .environment(PackageModel())
        .environment(BuildOptions())
        .frame(width: 500, height: 300)
}
