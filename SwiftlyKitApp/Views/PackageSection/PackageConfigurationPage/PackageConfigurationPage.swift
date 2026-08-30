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
        .background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: PackageSectionIdealHeightPreferenceKey.self,
                    value: geometry.size.height
                )
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            SectionSurface()
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

extension PackageConfigurationPage {

    private static let spacing: CGFloat = 14
    private static let horizontalPadding: CGFloat = 16
    private static let verticalPadding: CGFloat = 12
    private static let dividerOpacity = 0.55

}
