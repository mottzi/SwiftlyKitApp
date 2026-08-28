import SwiftUI

extension PackageBuildDetails.Header {
    
    struct PackageMenu: View {
        
        @Environment(PackageModel.self) private var packageModel

        var body: some View {
            Menu("Package actions", systemImage: "ellipsis.circle") {
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
            }
            .labelStyle(.iconOnly)
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("Package actions")
            .accessibilityLabel("Package actions")
        }
        
    }
    
}
