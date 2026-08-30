import SwiftUI

struct PackageSection: View {

    @Environment(PackageModel.self) private var packageModel

    @State private var layoutMode = PackageSectionLayoutMode.twoColumns

    var body: some View {
        PagingHStack(
            spacing: Self.pageSpacing,
            pageTrailingInset: Self.pageTrailingInset,
            selection: packageModel.packagePage
        ) {
            PackagePickerPage(layoutMode: layoutMode)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()

            PackageConfigurationPage()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()
                .deemphasiseContent(when: !packageModel.isPackageSelected)
                .scaleEffect(configurationScale, anchor: .bottomLeading)
                .rotationEffect(configurationRotation, anchor: .bottomLeading)
                .offset(configurationOffset)
        }
        .onPreferenceChange(PackageSectionLayoutModePreferenceKey.self) { reportedMode in
            guard let reportedMode else { return }
            layoutMode = reportedMode
        }
    }
}

extension PackageSection {

    private var configurationScale: CGFloat {
        packageModel.isPackageSelected
            ? 1
            : Self.inactiveConfigurationScale
    }

    private var configurationRotation: Angle {
        packageModel.isPackageSelected
            ? .zero
            : Self.inactiveConfigurationRotation
    }

    private var configurationOffset: CGSize {
        packageModel.isPackageSelected
            ? .zero
            : Self.inactiveConfigurationOffset
    }

}

extension PackageSection {

    private static let pageSpacing: CGFloat = 10
    private static let pageTrailingInset: CGFloat = 38
    private static let inactiveConfigurationScale: CGFloat = 0.9
    private static let inactiveConfigurationRotation = Angle.degrees(0.8)
    private static let inactiveConfigurationOffset = CGSize(width: 2, height: -2)

}
