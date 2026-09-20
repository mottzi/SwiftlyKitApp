import SwiftUI
import SwiftlyKit

/// Current build state with one contextual workflow action.
struct BuildStatus: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let state: BuildWorkflowState
    let result: BuildResult?
    let isPublishing: Bool
    let readyDetail: String?
    let onCancel: () -> Void
    let onExport: (URL) async throws -> BuildResult?

    var body: some View {
        HStack(spacing: Self.spacing) {
            statusIcon

            VStack(alignment: .leading, spacing: Self.textSpacing) {
                Text(presentation.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .contentTransition(.opacity)
                    .animation(transitionAnimation, value: presentation.title)

                Text(displayedDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(displayedDetail)
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
                    .transition(statusTransition)
            } else {
                Image(systemName: presentation.symbolName)
                    .foregroundStyle(presentation.symbolColor)
                    .symbolRenderingMode(.hierarchical)
                    .contentTransition(.symbolEffect(.replace))
                    .transition(statusTransition)
            }
        }
        .frame(width: Self.iconLength, height: Self.iconLength)
        .animation(transitionAnimation, value: iconPhase)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var statusAction: some View {
        ZStack {
            switch actionPhase {
                case .cancel:
                    cancelButton
                        .transition(statusTransition)

                case .showResult:
                    if let result {
                        BuildResultButton(
                            result: result,
                            isPublishing: isPublishing,
                            onExport: onExport
                        )
                            .transition(statusTransition)
                    }

                case .none:
                    EmptyView()
            }
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .frame(width: Self.actionLength, height: Self.actionLength)
        .animation(transitionAnimation, value: actionPhase)
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            Label("Cancel Build", systemImage: "stop.fill")
                .padding(4)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .keyboardShortcut(".", modifiers: .command)
        .help("Cancel build (⌘.)")
        .offset(x: 2, y: 0)
    }

}

extension BuildStatus {

    private var iconPhase: IconPhase {
        presentation.showsProgress
            ? .progress
            : .symbol(presentation.symbolName)
    }

    private var actionPhase: ActionPhase {
        switch state {
            case .active: .cancel
            case .succeeded where result != nil: .showResult
            case .idle, .cancelling, .succeeded, .failed, .cancelled: .none
        }
    }

    private var transitionAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: Self.transitionDuration)
    }

    private var statusTransition: AnyTransition {
        reduceMotion
            ? .identity
            : .opacity.combined(with: .scale(scale: Self.transitionScale))
    }

    private var displayedDetail: String {
        PathDisplay.abbreviatingHomeDirectory(in: presentation.detail)
    }

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
                    detail: result.map { PathDisplay.path(for: $0.executable) }
                        ?? "The executable is ready.",
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

    private enum IconPhase: Equatable {
        case progress
        case symbol(String)
    }

    private enum ActionPhase: Equatable {
        case none
        case cancel
        case showResult
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
    private static let transitionDuration = 0.25
    private static let transitionScale = 0.8

}
