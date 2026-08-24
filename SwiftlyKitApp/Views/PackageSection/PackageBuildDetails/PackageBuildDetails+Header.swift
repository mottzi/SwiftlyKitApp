import SwiftUI

extension PackageBuildDetails {

    struct Header: View {

        @Environment(AppState.self) private var appState

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
                    Text(appState.packageName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    Text(appState.displayPath)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(appState.displayPath)
                }

                Spacer(minLength: 8)

                PackageMenu()
            }
        }
    }

}
