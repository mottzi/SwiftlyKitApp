import SwiftUI

struct PackageBuildDetails: View {

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.detailsSpacing) {
            Header()
                .padding(.horizontal, Constants.detailsHorizontalPadding)
            Divider()
                .opacity(Constants.detailsDividerOpacity)
            ConfigurationSection()
                .padding(.leading, Constants.detailsHorizontalPadding)
                .padding(.trailing, Constants.configurationAccessoryTrailingPadding)
        }
        .padding(.vertical, Constants.detailsVerticalPadding)
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: Constants.sectionRadius)
                .fill(.quaternary.opacity(Constants.sectionFillOpacity))
                .strokeBorder(
                    Color.primary.opacity(Constants.sectionBorderOpacity),
                    lineWidth: Constants.sectionBorderWidth
                )
        }
    }

}

#Preview {
    PackageBuildDetails()
        .environment(PackageModel())
        .environment(BuildOptions())
        .frame(
            width: Constants.windowSize.width,
            height: Constants.windowSize.height
        )
}
