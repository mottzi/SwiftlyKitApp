import SwiftUI

extension PackageBuildDetails.Header {
    
    struct PackageMenu: View {
        
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

                Button("Close Package", systemImage: "xmark.circle", role: .destructive) {
                    withAnimation {
                        packageModel.clearPackage()
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(
                        width: Constants.menuButtonLength,
                        height: Constants.menuButtonLength
                    )
                    .contentShape(.rect)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("Package actions")
            .accessibilityLabel("Package actions")
        }
        
    }
    
}
