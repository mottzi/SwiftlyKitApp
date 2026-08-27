import SwiftUI

struct PackageSection: View {

    @Environment(PackageModel.self) private var packageModel

    var body: some View {
        PagingHStack(
            spacing: Constants.pageSpacing,
            pageTrailingInset: Constants.pageTrailingInset,
            selection: packageModel.packagePage
        ) {
            PackagePicker()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()

            PackageBuildDetails()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .geometryGroup()
                .saturation(detailsSaturation)
                .opacity(detailsOpacity)
                .scaleEffect(detailsScale, anchor: .bottomLeading)
                .rotationEffect(detailsRotation, anchor: .bottomLeading)
                .offset(detailsOffset)
        }
    }
}

extension PackageSection {

    private var detailsSaturation: Double {
        packageModel.isPackageSelected
            ? 1
            : Constants.inactiveSaturation
    }

    private var detailsOpacity: Double {
        packageModel.isPackageSelected
            ? 1
            : Constants.inactiveOpacity
    }

    private var detailsScale: CGFloat {
        packageModel.isPackageSelected
            ? 1
            : Constants.inactiveDetailsScale
    }

    private var detailsRotation: Angle {
        packageModel.isPackageSelected
            ? .zero
            : Constants.inactiveDetailsRotation
    }

    private var detailsOffset: CGSize {
        packageModel.isPackageSelected
            ? .zero
            : Constants.inactiveDetailsOffset
    }

}
