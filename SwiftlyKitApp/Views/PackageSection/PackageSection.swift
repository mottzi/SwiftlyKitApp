import SwiftUI

struct PackageSection: View {

    @Environment(PackageModel.self) private var packageModel

    var body: some View {
        PagingHStack(spacing: 10, pageTrailingInset: 38, selection: packageModel.packagePage) {
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
            : 0
    }

    private var detailsOpacity: Double {
        packageModel.isPackageSelected
            ? 1
            : 0.65
    }

    private var detailsScale: CGFloat {
        packageModel.isPackageSelected
            ? 1
            : 0.9
    }

    private var detailsRotation: Angle {
        packageModel.isPackageSelected
            ? .zero
            : .degrees(0.8)
    }

    private var detailsOffset: CGSize {
        packageModel.isPackageSelected
            ? .zero
            : CGSize(width: 2, height: -2)
    }

}
