import SwiftUI

struct PackageConfigurationPage: View {

    var body: some View {
        VStack(alignment: .leading, spacing: Self.spacing) {
            PackageHeader()
                .padding(.horizontal, Self.horizontalPadding)
            Divider()
                .opacity(Self.dividerOpacity)
            PackageConfigurator()
                .padding(.leading, Self.horizontalPadding)
                .padding(.trailing, ConfigurationAccessoryMetrics.spacing)
        }
        .padding(.vertical, Self.verticalPadding)
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: SectionSurfaceMetrics.cornerRadius)
                .fill(.quaternary.opacity(SectionSurfaceMetrics.fillOpacity))
                .strokeBorder(
                    Color.primary.opacity(SectionSurfaceMetrics.borderOpacity),
                    lineWidth: SectionSurfaceMetrics.borderWidth
                )
        }
    }

}

#Preview {
    PackageConfigurationPage()
        .environment(PackageModel())
        .environment(BuildOptions())
        .frame(
            width: SwiftlyKitApp.defaultWindowSize.width,
            height: SwiftlyKitApp.defaultWindowSize.height
        )
}

private extension PackageConfigurationPage {

    static let spacing: CGFloat = 14
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 12
    static let dividerOpacity = 0.55

}
