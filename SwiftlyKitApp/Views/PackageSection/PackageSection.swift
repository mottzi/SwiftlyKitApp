import SwiftUI

struct PackageSection: View {

    @Environment(PackageModel.self) private var packageModel

    @State private var arrangement = AdaptiveGridArrangement.twoColumns
    @State private var sectionHeight: CGFloat?

    var body: some View {
        PagingHStack(
            spacing: Self.pageSpacing,
            pageTrailingInset: Self.pageTrailingInset,
            selection: packageModel.packagePage
        ) {
            PackagePickerPage(arrangement: arrangement)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()

            PackageConfigurationPage(onContentHeightChange: updateSectionHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()
                .deemphasiseContent(when: !packageModel.isPackageSelected)
                .scaleEffect(configurationScale, anchor: .bottomLeading)
                .rotationEffect(configurationRotation, anchor: .bottomLeading)
                .offset(configurationOffset)
        }
        .frame(height: sectionHeight, alignment: .top)
        .onAdaptiveGridArrangementChange { reportedArrangement in
            guard reportedArrangement != arrangement else { return }
            arrangement = reportedArrangement
        }
    }
}

extension PackageSection {

    private func updateSectionHeight(_ contentHeight: CGFloat) {
        guard contentHeight.isFinite, contentHeight > 0 else { return }
        guard sectionHeight != contentHeight else { return }

        if sectionHeight == nil {
            sectionHeight = contentHeight
        } else {
            withAnimation(PackageLayoutAnimation.adaptiveChange) {
                sectionHeight = contentHeight
            }
        }
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

extension PackageSection {

    private static let pageSpacing: CGFloat = 10
    private static let pageTrailingInset: CGFloat = 38
    private static let inactiveConfigurationScale: CGFloat = 0.9
    private static let inactiveConfigurationRotation = Angle.degrees(0.8)
    private static let inactiveConfigurationOffset = CGSize(width: 2, height: -2)

}
