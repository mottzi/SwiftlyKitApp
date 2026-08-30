import SwiftUI

struct PackageSection: View {

    @Environment(PackageModel.self) private var packageModel

    @State private var layoutMode = LayoutMode.twoColumns
    @State private var presentedHeight: CGFloat?

    var body: some View {
        PagingHStack(
            spacing: Self.pageSpacing,
            pageTrailingInset: Self.pageTrailingInset,
            heightReferencePage: PackageModel.Page.configuration.rawValue,
            selection: packageModel.packagePage
        ) {
            PackagePickerPage(layoutMode: layoutMode)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()

            PackageConfigurationPage(onIdealHeightChange: updatePresentedHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()
                .deemphasiseContent(when: !packageModel.isPackageSelected)
                .scaleEffect(configurationScale, anchor: .bottomLeading)
                .rotationEffect(configurationRotation, anchor: .bottomLeading)
                .offset(configurationOffset)
        }
        .frame(height: presentedHeight, alignment: .top)
        .onPreferenceChange(LayoutMode.PreferenceKey.self) { reportedMode in
            guard let reportedMode else { return }
            layoutMode = reportedMode
        }
    }
}

extension PackageSection {

    private func updatePresentedHeight(_ idealHeight: CGFloat) {
        guard idealHeight.isFinite, idealHeight > 0 else { return }
        guard presentedHeight != idealHeight else { return }

        if presentedHeight == nil {
            presentedHeight = idealHeight
        } else {
            withAnimation(.bouncy.speed(Self.layoutTransitionSpeed)) {
                presentedHeight = idealHeight
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

    /// Form arrangement shared by the package configuration and package picker label.
    enum LayoutMode {

        case oneColumn
        case twoColumns

    }

}

extension PackageSection.LayoutMode {

    /// Carries the configuration form's selected arrangement to `PackageSection`.
    struct PreferenceKey: SwiftUI.PreferenceKey {

        static let defaultValue: PackageSection.LayoutMode? = nil

        static func reduce(
            value: inout PackageSection.LayoutMode?,
            nextValue: () -> PackageSection.LayoutMode?
        ) {
            value = nextValue() ?? value
        }

    }
}

extension PackageSection {

    private static let pageSpacing: CGFloat = 10
    private static let pageTrailingInset: CGFloat = 38
    private static let layoutTransitionSpeed = 1.25
    private static let inactiveConfigurationScale: CGFloat = 0.9
    private static let inactiveConfigurationRotation = Angle.degrees(0.8)
    private static let inactiveConfigurationOffset = CGSize(width: 2, height: -2)

}
