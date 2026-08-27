import SwiftUI

struct BuildSection: View {

    @Environment(PackageModel.self) private var packageModel
    @Environment(BuildOptions.self) private var buildOptions

    var body: some View {
        RoundedRectangle(cornerRadius: Constants.sectionRadius)
            .fill(.quaternary.opacity(Constants.sectionFillOpacity))
            .strokeBorder(
                Color.primary.opacity(Constants.sectionBorderOpacity),
                lineWidth: Constants.sectionBorderWidth
            )
        .frame(minHeight: Constants.minBuildSectionHeight)
            .saturation(
                buildOptions.hasValidSelections ? 1 : Constants.inactiveSaturation
            )
            .opacity(
                buildOptions.hasValidSelections ? 1 : Constants.inactiveOpacity
            )
            .disabled(!packageModel.isPackageSelected)
    }
    
}
