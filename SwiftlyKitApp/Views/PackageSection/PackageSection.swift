import SwiftUI

struct PackageSection: View {

    @Environment(PackageModel.self) private var packageModel

    var body: some View {
        PagingHStack(
            spacing: Self.pageSpacing,
            pageTrailingInset: Self.pageTrailingInset,
            selection: packageModel.packagePage
        ) {
            PackagePickerPage()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()

            PackageConfigurationPage()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()
                .saturation(configurationSaturation)
                .opacity(configurationOpacity)
                .scaleEffect(configurationScale, anchor: .bottomLeading)
                .rotationEffect(configurationRotation, anchor: .bottomLeading)
                .offset(configurationOffset)
        }
    }
}

extension PackageSection {

    private var configurationSaturation: Double {
        packageModel.isPackageSelected
            ? 1
            : InactiveContentMetrics.saturation
    }

    private var configurationOpacity: Double {
        packageModel.isPackageSelected
            ? 1
            : InactiveContentMetrics.opacity
    }

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

private extension PackageSection {

    static let pageSpacing: CGFloat = 10
    static let pageTrailingInset: CGFloat = 38
    static let inactiveConfigurationScale: CGFloat = 0.9
    static let inactiveConfigurationRotation = Angle.degrees(0.8)
    static let inactiveConfigurationOffset = CGSize(width: 2, height: -2)

}
