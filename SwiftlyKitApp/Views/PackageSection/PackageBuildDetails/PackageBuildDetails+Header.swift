import SwiftUI

extension PackageBuildDetails {

    struct Header: View {

        @Environment(PackageModel.self) private var packageModel

        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "swift")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.monochrome)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(packageModel.packageName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    Text(packageModel.displayPath)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(packageModel.displayPath)
                }
                .frame(
                    minWidth: 0,
                    idealWidth: 0,
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .layoutPriority(-1)

                Spacer(minLength: 0)

                PackageMenu()
            }
        }
    }

}
