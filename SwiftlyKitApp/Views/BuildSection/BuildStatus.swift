import SwiftUI
import SwiftlyKit

/// Current build state with one contextual workflow action.
struct BuildStatus: View {

    let state: BuildWorkflowState
    let result: BuildResult?
    let readyDetail: String?
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: Self.spacing) {
            statusIcon

            VStack(alignment: .leading, spacing: Self.textSpacing) {
                Text(presentation.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(presentation.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(presentation.detail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            statusAction
        }
        .padding(.horizontal, Self.horizontalPadding)
        .frame(height: Self.height)
        .accessibilityElement(children: .contain)
    }

}

extension BuildStatus {

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            if presentation.showsProgress {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: presentation.symbolName)
                    .foregroundStyle(presentation.symbolColor)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .frame(width: Self.iconLength, height: Self.iconLength)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var statusAction: some View {
        ZStack {
            switch state {
                case .active:
                    Button("Cancel Build", systemImage: "stop.fill", action: onCancel)
                        .labelStyle(.iconOnly)
                        .keyboardShortcut(".", modifiers: .command)
                        .help("Cancel build (⌘.)")

                case .succeeded:
                    if result != nil {
                        Button("Show Build in Finder", systemImage: "folder", action: showResult)
                            .labelStyle(.iconOnly)
                            .help("Show build in Finder")
                    }

                case .idle, .cancelling, .failed, .cancelled:
                    EmptyView()
            }
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .frame(width: Self.actionLength, height: Self.actionLength)
    }

    private func showResult() {
        guard let result else { return }
        NSWorkspace.shared.activateFileViewerSelecting([result.executable])
    }

}

extension BuildStatus {

    private var presentation: Presentation {
        switch state {
            case .idle:
                if let readyDetail {
                    Presentation(
                        title: "Ready to build",
                        detail: readyDetail,
                        symbolName: "hammer.fill",
                        symbolColor: .accentColor
                    )
                } else {
                    Presentation(
                        title: "Build",
                        detail: "Complete package discovery to enable building.",
                        symbolName: "hammer",
                        symbolColor: .secondary
                    )
                }

            case .active(let phase, let detail):
                Presentation(
                    title: phase.title,
                    detail: detail,
                    symbolName: "circle",
                    symbolColor: .secondary,
                    showsProgress: true
                )

            case .cancelling:
                Presentation(
                    title: "Cancelling build",
                    detail: "Waiting for the active command to stop.",
                    symbolName: "circle",
                    symbolColor: .secondary,
                    showsProgress: true
                )

            case .succeeded:
                Presentation(
                    title: "Build succeeded",
                    detail: result?.executable.path(percentEncoded: false) ?? "The executable is ready.",
                    symbolName: "checkmark.circle.fill",
                    symbolColor: .green
                )

            case .failed(let detail):
                Presentation(
                    title: "Build failed",
                    detail: detail,
                    symbolName: "exclamationmark.triangle.fill",
                    symbolColor: .red
                )

            case .cancelled:
                Presentation(
                    title: "Build cancelled",
                    detail: "The build stopped before completion.",
                    symbolName: "stop.circle.fill",
                    symbolColor: .secondary
                )
        }
    }

    private struct Presentation {
        let title: String
        let detail: String
        let symbolName: String
        let symbolColor: Color
        var showsProgress = false
    }

}

extension BuildWorkflowPhase {

    fileprivate var title: String {
        switch self {
            case .building: "Building"
            case .resolvingDependencies: "Resolving dependencies"
            case .stripping: "Stripping executable"
        }
    }

}

extension BuildStatus {

    private static let height: CGFloat = 48
    private static let spacing: CGFloat = 10
    private static let textSpacing: CGFloat = 1
    private static let horizontalPadding: CGFloat = 12
    private static let iconLength: CGFloat = 17
    private static let actionLength: CGFloat = 24

}
