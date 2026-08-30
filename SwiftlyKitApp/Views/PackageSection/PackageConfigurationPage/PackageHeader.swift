import SwiftUI

struct PackageHeader: View {

    @Environment(PackageModel.self) private var packageModel

    var body: some View {
        HStack(alignment: .center, spacing: SectionHeaderMetrics.contentSpacing) {
            Image(systemName: "swift")
                .resizable()
                .scaledToFit()
                .frame(
                    width: SectionHeaderMetrics.iconSlotLength,
                    height: SectionHeaderMetrics.iconSlotLength
                )
                .foregroundStyle(.orange)
                .symbolRenderingMode(.monochrome)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: SectionHeaderMetrics.textSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: Self.titleSpacing) {
                    Text(packageModel.packageName)
                        .font(.system(size: Self.titleFontSize, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(Self.lineLimit)

                    PackageActionsMenu()
                }

                Text(packageModel.displayPath)
                    .font(.system(size: SectionHeaderMetrics.subtitleFontSize))
                    .foregroundStyle(.secondary)
                    .lineLimit(Self.lineLimit)
                    .truncationMode(.middle)
                    .help(packageModel.displayPath)
            }
            .frame(
                minWidth: 0,
                idealWidth: 0,
                maxWidth: .infinity,
                alignment: .leading
            )
            .layoutPriority(Self.textPriority)

            BuildButton()
        }
        .padding(.horizontal, SectionHeaderMetrics.horizontalPadding)
        .frame(height: SectionHeaderMetrics.height)
    }

}

extension PackageHeader {

    private static let titleSpacing: CGFloat = 4
    private static let titleFontSize: CGFloat = 13
    private static let lineLimit = 1
    private static let textPriority = -1.0

}
