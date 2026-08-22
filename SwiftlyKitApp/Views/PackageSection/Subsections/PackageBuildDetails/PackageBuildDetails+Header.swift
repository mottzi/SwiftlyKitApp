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

                    PackageLabel()
                }

                Spacer(minLength: 8)

                PackageMenu()
            }
        }
    }
    
}

extension PackageBuildDetails {
    
    struct PackageLabel: View {
        
        @Environment(AppState.self) private var appState
        
        var body: some View {
            Text(appState.displayPath)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(appState.displayPath)
                .contextMenu {
                    if let url = appState.packageURL {
                        Button("Open in Finder") {
                            NSWorkspace.shared.open(url)
                        }
                        Button("Copy Path") {
                            NSPasteboard.general.setURL(url)
                        }
                    }
                }
        }
        
    }
    
}
