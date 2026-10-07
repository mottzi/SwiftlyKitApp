import SwiftUI

/// Package picker and configuration pages that share an adaptive section height.
struct PackageSection: View {

    @Environment(PackageModel.self) private var packageModel
    @Environment(\.appearsActive) private var appearsActive

    @State private var arrangement: AdaptiveGridArrangement?
    @State private var hasEstablishedWindowArrangement = false

    var body: some View {
        PagingHStack(
            spacing: Self.pageSpacing,
            pageTrailingInset: Self.pageTrailingInset,
            selection: packageModel.packagePage
        ) {
            PackagePickerPage(arrangement: arrangement ?? .twoColumns)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()

            PackageConfigurationPage(arrangement: arrangement)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()
                .deemphasiseContent(when: !packageModel.isPackageSelected)
                .scaleEffect(configurationScale, anchor: .bottomLeading)
                .rotationEffect(configurationRotation, anchor: .bottomLeading)
                .offset(configurationOffset)
        }
        .onAdaptiveGridArrangementChange { reportedArrangement in
            // Establish the first active window layout before animating later column changes.
            let animatesChange = hasEstablishedWindowArrangement && appearsActive
            if appearsActive { hasEstablishedWindowArrangement = true }
            guard reportedArrangement != arrangement else { return }
            if animatesChange {
                withAnimation(PackageLayoutAnimation.adaptiveChange) {
                    arrangement = reportedArrangement
                }
            } else {
                arrangement = reportedArrangement
            }
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
