import SwiftUI

struct PackageHeader: View {

    @Environment(PackageModel.self) private var packageModel

    var body: some View {
        HStack(alignment: .center, spacing: Self.spacing) {
            Image(systemName: "swift")
                .resizable()
                .scaledToFit()
                .frame(
                    width: Self.iconLength,
                    height: Self.iconLength
                )
                .foregroundStyle(.orange)
                .symbolRenderingMode(.monochrome)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Self.textSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: Self.titleSpacing) {
                    Text(packageModel.packageName)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .lineLimit(Self.lineLimit)

                    PackageActionsMenu()
                }

                Text(packageModel.displayPath)
                    .font(.system(size: Self.pathFontSize))
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

            Spacer(minLength: 0)

            BuildButton()
                .offset(x: 4, y: 0)
        }
    }

}

extension PackageHeader {

    private static let spacing: CGFloat = 12
    private static let iconLength: CGFloat = 26
    private static let textSpacing: CGFloat = 2
    private static let titleSpacing: CGFloat = 4
    private static let pathFontSize: CGFloat = 11
    private static let lineLimit = 1
    private static let textPriority = -1.0

}
