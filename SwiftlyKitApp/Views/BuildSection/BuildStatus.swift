import SwiftUI
import SwiftlyKit

/// Current setup or build state with one contextual workflow action.
struct BuildStatus: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var failureDetailsPresented = false
    @State private var visiblePresentation: Presentation?
    @State private var progressVisibleUntil: ContinuousClock.Instant?

    let state: BuildWorkflowState
    let result: BuildResult?
    let isPublishing: Bool
    let readyDetail: String?
    var setupStatus: BuildSetupStatus? = nil
    var identity: BuildIdentity? = nil
    var onSetupAction: () -> Void = {}
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
        .task(id: requestedPresentation) {
            await updatePresentation()
        }
    }

}

extension BuildStatus {

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            if presentation.showsProgress {
                ProgressView()
                    .controlSize(.small)
                    .transition(.opacity)
            } else {
                Image(systemName: presentation.symbolName)
                    .font(.system(size: presentation.symbolSize))
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
                            identity: identity,
                            onExport: onExport
                        )
                            .transition(statusTransition)
                    }

                case .setup:
                    if let action = setupStatus?.action {
                        Button(action.label, systemImage: action.symbol, action: onSetupAction)
                            .labelStyle(.iconOnly)
                            .help(action.label)
                            .transition(statusTransition)
                    }

                case .failureDetails:
                    Button("Show Build Failure Details", systemImage: "info.circle") {
                        failureDetailsPresented = true
                    }
                    .labelStyle(.iconOnly)
                    .help("Show build failure details")
                    .popover(isPresented: $failureDetailsPresented, arrowEdge: .trailing) {
                        if case .failed(let detail) = state {
                            failureDetails(detail)
                        }
                    }
                    .transition(statusTransition)

                case .none:
                    EmptyView()
            }
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .frame(width: Self.actionLength, height: Self.actionLength)
        .animation(transitionAnimation, value: actionPhase)
    }

    private func failureDetails(_ detail: String) -> some View {

        VStack(alignment: .leading, spacing: 12) {
            Text("Build failed")
                .font(.headline)

            ScrollView {
                Text(detail)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)

            Button("Copy Details", systemImage: "doc.on.doc") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(detail, forType: .string)
            }
        }
        .padding()
        .frame(width: 420, alignment: .leading)
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
        if let setupStatus, !state.isRunning {
            return setupStatus.action == nil ? .none : .setup
        }

        return switch state {
            case .active: .cancel
            case .succeeded where result != nil: .showResult
            case .failed: .failureDetails
            case .idle, .cancelling, .succeeded, .cancelled: .none
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

    private var isChecking: Bool {
        setupStatus?.showsProgress == true && !state.isRunning
    }

    private var presentation: Presentation {
        if presentsImmediately { return requestedPresentation }
        return visiblePresentation ?? Presentation(
            title: "Checking build configuration",
            detail: "Validating the selected package and Swift environment.",
            symbolName: "hammer",
            symbolColor: .secondary
        )
    }

    private var requestedPresentation: Presentation {
        checkingPresentation ?? currentPresentation
    }

    private var presentsImmediately: Bool {
        if state.isRunning { return true }
        if case .failed = state { return true }
        if setupStatus?.action != nil { return true }
        return state == .idle && readyDetail == nil && setupStatus == nil
    }

    private func updatePresentation() async {

        if presentsImmediately {
            visiblePresentation = requestedPresentation
            progressVisibleUntil = nil
            return
        }
        guard visiblePresentation != requestedPresentation else { return }

        let clock = ContinuousClock()
        var deadline = clock.now
        if isChecking { deadline += .milliseconds(300) }
        if let progressVisibleUntil { deadline = max(deadline, progressVisibleUntil) }

        do {
            try await clock.sleep(until: deadline)
            try Task.checkCancellation()
            visiblePresentation = requestedPresentation
            progressVisibleUntil = isChecking ? clock.now + .milliseconds(500) : nil
        } catch { }
    }

    private var checkingPresentation: Presentation? {
        guard isChecking else { return nil }
        if setupStatus?.isInstalling == true { return currentPresentation }
        return Presentation(
            title: "Checking build configuration",
            detail: "Validating the selected package and Swift environment.",
            symbolName: "hammer",
            symbolColor: .secondary,
            showsProgress: true
        )
    }

    private var currentPresentation: Presentation {
        if let setupStatus, !state.isRunning {
            return Presentation(
                title: setupStatus.title,
                detail: setupStatus.detail,
                symbolName: "exclamationmark.circle",
                symbolColor: .secondary,
                showsProgress: setupStatus.showsProgress
            )
        }

        return switch state {
            case .idle:
                if let readyDetail {
                    Presentation(
                        title: "Ready to build",
                        detail: readyDetail,
                        symbolName: "hammer.fill",
                        symbolColor: .accentColor,
                        symbolSize: Self.hammerSymbolSize
                    )
                } else {
                    Presentation(
                        title: "Build",
                        detail: "Choose a Swift package to start.",
                        symbolName: "hammer",
                        symbolColor: .secondary,
                        symbolSize: Self.hammerSymbolSize
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
                    title: "Last build succeeded",
                    detail: identity?.summary ?? result.map { PathDisplay.path(for: $0.executable) }
                        ?? "The executable is ready.",
                    symbolName: "checkmark.circle.fill",
                    symbolColor: .green
                )

            case .failed(let detail):
                Presentation(
                    title: "Build failed",
                    detail: state.failureSummary ?? detail,
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

    private struct Presentation: Equatable {
        let title: String
        let detail: String
        let symbolName: String
        let symbolColor: Color
        var symbolSize = BuildStatus.defaultSymbolSize
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
        case setup
        case failureDetails
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
    private static let defaultSymbolSize: CGFloat = 20
    private static let hammerSymbolSize: CGFloat = 17
    private static let actionLength: CGFloat = 24
    private static let transitionDuration = 0.25
    private static let transitionScale = 0.8

}
