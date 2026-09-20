import AppKit
import SwiftUI
import SwiftlyKit

/// Latest successful build files with reveal and export actions.
struct BuildResultButton: View {

    @State private var isPopoverPresented = false
    @State private var publicationError: String?

    let result: BuildResult
    let isPublishing: Bool
    let onExport: (URL) async throws -> BuildResult?

    var body: some View {
        ZStack {
            if isPublishing {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Exporting build")
            } else {
                Button {
                    isPopoverPresented = true
                } label: {
                    Label("Build files", systemImage: "folder.fill")
                        .padding(4)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .help("Build files")
                .accessibilityLabel("Build files")
                .offset(x: 2, y: 0)
                .popover(isPresented: $isPopoverPresented, arrowEdge: .trailing) {
                    BuildResultPopover(
                        result: result,
                        onExport: export,
                        onReveal: revealSourceFiles
                    )
                }
            }
        }
        .alert("Export Failed", isPresented: errorPresented) {
            Button("OK") { }
        } message: {
            Text(publicationError ?? "The build could not be exported.")
        }
    }

}

extension BuildResultButton {

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { publicationError != nil },
            set: { isPresented in
                if !isPresented {
                    publicationError = nil
                }
            }
        )
    }

    private func export() {

        guard !isPublishing else { return }

        Task {
            guard let destination = await BuildExportPanel.destination() else {
                return
            }

            isPopoverPresented = false

            do {
                guard let publishedResult = try await onExport(destination) else {
                    publicationError = "The build changed before it could be exported. Try again."
                    return
                }
                reveal(publishedResult)
            } catch SwiftlyKitError.outputAlreadyExists {
                publicationError = "Choose or create an empty folder for the exported build."
            } catch {
                publicationError = error.localizedDescription
            }
        }
    }

    private func revealSourceFiles() {
        isPopoverPresented = false
        reveal(result)
    }

    private func reveal(_ result: BuildResult) {
        NSWorkspace.shared.activateFileViewerSelecting(
            [result.executable] + result.resourceBundles
        )
    }

}

/// Compact inventory and actions for one successful build.
private struct BuildResultPopover: View {

    let result: BuildResult
    let onExport: () -> Void
    let onReveal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Self.spacing) {
            Text("Build files")
                .font(.headline)

            VStack(alignment: .leading, spacing: Self.fileSpacing) {
                BuildResultFileRow(
                    name: result.executableName,
                    systemImage: "terminal"
                )

                ForEach(result.resourceBundles, id: \.self) { resourceBundle in
                    BuildResultFileRow(
                        name: resourceBundle.lastPathComponent,
                        systemImage: "folder"
                    )
                }
            }

            Divider()

            Button(action: onExport) {
                Label("Export Build…", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button(action: onReveal) {
                Label("Show in Finder", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: Self.width, alignment: .leading)
    }

}

extension BuildResultPopover {

    private static let width: CGFloat = 280
    private static let spacing: CGFloat = 10
    private static let fileSpacing: CGFloat = 8

}

private struct BuildResultFileRow: View {

    let name: String
    let systemImage: String

    var body: some View {
        Label {
            Text(name)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(name)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

private enum BuildExportPanel {

    static func destination() async -> URL? {

        let panel = NSOpenPanel()
        panel.title = "Export Build"
        panel.message = "Choose or create an empty folder for the exported build."
        panel.prompt = "Export"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        return await withCheckedContinuation { continuation in
            panel.begin { response in
                continuation.resume(returning: response == .OK ? panel.url : nil)
            }
        }
    }

}
