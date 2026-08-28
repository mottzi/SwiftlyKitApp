import SwiftUI

extension PackageBuildDetails {

    struct Header: View {

        @Environment(PackageModel.self) private var packageModel

        var body: some View {
            HStack(alignment: .center, spacing: Constants.headerSpacing) {
                Image(systemName: "swift")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: Constants.headerIconLength,
                        height: Constants.headerIconLength
                    )
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.monochrome)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Constants.headerTextSpacing) {
                    Text(packageModel.packageName)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .lineLimit(Constants.headerLineLimit)

                    Text(packageModel.displayPath)
                        .font(.system(size: Constants.pathFontSize))
                        .foregroundStyle(.secondary)
                        .lineLimit(Constants.headerLineLimit)
                        .truncationMode(.middle)
                        .help(packageModel.displayPath)
                }
                .frame(
                    minWidth: 0,
                    idealWidth: 0,
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .layoutPriority(Constants.headerTextPriority)

                Spacer(minLength: 0)

                PackageMenu()
            }
        }
    }

}
