import SwiftUI

/// Fixed-width discovery feedback with one information or status popover anchor.
struct DiscoveryAccessory<StatusContent: View>: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var progressVisible = false

    @Binding private var infoPopoverPresented: Bool
    @Binding private var statusPopoverPresented: Bool

    private let option: BuildOptionInfo
    private let presentation: DiscoveryAccessoryPresentation
    private let statusContent: StatusContent

    init(
        infoPopoverPresented: Binding<Bool>,
        statusPopoverPresented: Binding<Bool>,
        option: BuildOptionInfo,
        presentation: DiscoveryAccessoryPresentation,
        statusContent: () -> StatusContent
    ) {
        _infoPopoverPresented = infoPopoverPresented
        _statusPopoverPresented = statusPopoverPresented
        self.option = option
        self.presentation = presentation
        self.statusContent = statusContent()
    }

    var body: some View {
        ZStack {
            content
        }
        .animation(.easeInOut(duration: Self.transitionDuration), value: phase)
        .frame(
            width: ConfigurationAccessoryMetrics.length,
            height: ConfigurationAccessoryMetrics.length
        )
        .geometryGroup()
        .task(id: isProgress) {
            progressVisible = false
            guard isProgress else { return }
            do {
                try await Task.sleep(for: .milliseconds(300))
                progressVisible = true
            } catch { }
        }
        .onChange(of: phase) {
            reconcilePopovers()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch displayedPresentation {
            case .information:
                BuildOptionInfoButton(
                    isPresented: $infoPopoverPresented,
                    option: option
                )
                .transition(indicatorTransition)

            case .progress(let accessibilityLabel):
                progressButton(accessibilityLabel: accessibilityLabel)
                    .transition(indicatorTransition)

            case .status(let status):
                statusButton(status)
                    .transition(indicatorTransition)
        }
    }

    private var isProgress: Bool {
        if case .progress = presentation { return true }
        return false
    }

    private var displayedPresentation: DiscoveryAccessoryPresentation {
        isProgress && !progressVisible ? .information : presentation
    }

    private var phase: Phase {
        switch displayedPresentation {
            case .information: .information
            case .progress: .progress
            case .status: .status
        }
    }

    private var indicatorTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .opacity.combined(with: .scale(scale: Self.transitionScale))
    }

    private func progressButton(accessibilityLabel: String) -> some View {
        popoverButton(accessibilityLabel: accessibilityLabel) {
            DiscoverySpinner(accessibilityLabel: accessibilityLabel)
        }
        .accessibilityValue("In progress")
    }

    private func statusButton(_ status: DiscoveryAccessoryPresentation.Status) -> some View {
        popoverButton(accessibilityLabel: status.label) {
            Image(systemName: status.symbol)
        }
        .foregroundStyle(status.color)
    }

    private func popoverButton<Label: View>(
        accessibilityLabel: String,
        @ViewBuilder label: () -> Label
    ) -> some View {
        Button(
            action: { statusPopoverPresented = true },
            label: label
        )
        .buttonStyle(.borderless)
        .controlSize(.small)
        .help(accessibilityLabel)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .popover(isPresented: $statusPopoverPresented, arrowEdge: .trailing) {
            statusContent
                .padding()
                .frame(width: Self.popoverWidth, alignment: .leading)
        }
    }

    private func reconcilePopovers() {
        switch phase {
            case .information:
                statusPopoverPresented = false
            case .progress, .status:
                infoPopoverPresented = false
        }
    }

    private enum Phase {
        case information
        case progress
        case status
    }

}

extension DiscoveryAccessory {

    private static var transitionDuration: Double { 0.4 }
    private static var transitionScale: Double { 0.8 }
    private static var popoverWidth: CGFloat { 320 }

}
