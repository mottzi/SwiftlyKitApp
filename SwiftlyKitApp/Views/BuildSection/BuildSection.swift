import SwiftUI

struct BuildSection: View {

    @Environment(PackageModel.self) private var packageModel
    @Environment(BuildOptions.self) private var buildOptions

    var body: some View {
        SectionSurface()
            .frame(minHeight: Self.minimumHeight)
            .deemphasiseContent(when: !hasPreparedPackage)
    }

    private var hasPreparedPackage: Bool {
        guard let packageRoot = packageModel.packageURL else { return false }
        return buildOptions.preparedPackage(in: packageRoot) != nil
    }

}

extension BuildSection {

    static let minimumHeight: CGFloat = 80

}
