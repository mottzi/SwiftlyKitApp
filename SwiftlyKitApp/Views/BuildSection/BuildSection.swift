import SwiftUI

struct BuildSection: View {

    @Environment(PackageModel.self) private var packageModel
    @Environment(BuildOptions.self) private var buildOptions

    var body: some View {
        RoundedRectangle(cornerRadius: SectionSurfaceMetrics.cornerRadius)
            .fill(.quaternary.opacity(SectionSurfaceMetrics.fillOpacity))
            .strokeBorder(
                Color.primary.opacity(SectionSurfaceMetrics.borderOpacity),
                lineWidth: SectionSurfaceMetrics.borderWidth
            )
        .frame(minHeight: BuildSectionMetrics.minimumHeight)
            .saturation(
                buildOptions.hasValidSelections ? 1 : InactiveContentMetrics.saturation
            )
            .opacity(
                buildOptions.hasValidSelections ? 1 : InactiveContentMetrics.opacity
            )
            .disabled(!packageModel.isPackageSelected)
    }
    
}
