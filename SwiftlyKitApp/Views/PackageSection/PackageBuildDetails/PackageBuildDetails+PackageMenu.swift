import SwiftUI

extension PackageBuildDetails.Header {
    
    struct PackageMenu: View {
        
        @Environment(AppState.self) private var appState

        var body: some View {
            Menu {
                if let url = appState.packageURL {
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

                Button("Choose Another Package…", systemImage: "folder.badge.plus") {
                    appState.isFileImporterPresented = true
                }

                Divider()

                Button("Close Package", systemImage: "xmark.circle", role: .destructive) {
                    appState.clearPackage()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(.rect)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("Package actions")
            .accessibilityLabel("Package actions")
        }
        
    }
    
}
