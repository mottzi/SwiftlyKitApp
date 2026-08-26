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
    }
}

#Preview {
    PackageSection()
        .environment(PackageModel())
        .environment(BuildOptions())
        .frame(width: 500, height: 300)
}
