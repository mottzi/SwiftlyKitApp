import SwiftUI

struct PackageActionsMenu: View {

    @Environment(PackageModel.self) private var packageModel

    var body: some View {

        Menu {
            if let url = packageModel.packageURL {
                Button("Show in Finder", systemImage: "folder") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }

                Button("Copy Path", systemImage: "doc.on.doc") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(
                        url.path(percentEncoded: false),
                        forType: .string
                    )
                }
            }

            Divider()

            Button("Close Package", systemImage: "xmark", role: .destructive) {
                withAnimation {
                    packageModel.clearPackage()
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .tint(Color.secondary.opacity(ConfigurationAccessoryMetrics.opacity))
                .foregroundStyle(Color.secondary.opacity(ConfigurationAccessoryMetrics.opacity))

        }
        .labelStyle(.iconOnly)
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .controlSize(.small)
        .help("Package actions")
        .accessibilityLabel("Package actions")
    }

}
