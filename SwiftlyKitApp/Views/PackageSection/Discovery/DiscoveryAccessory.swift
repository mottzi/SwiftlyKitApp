import SwiftUI

/// Fixed-width discovery feedback with one information or status popover anchor.
struct DiscoveryAccessory<StatusContent: View>: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .onChange(of: phase) {
            reconcilePopovers()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch presentation {
            case .information:
                BuildOptionInfoButton(
                    isPresented: $infoPopoverPresented,
                    option: option
                )
                .transition(indicatorTransition)

            case .progress(let accessibilityLabel):
                DiscoverySpinner(accessibilityLabel: accessibilityLabel)
                    .transition(indicatorTransition)

            case .status(let status):
                statusButton(status)
                    .transition(indicatorTransition)
        }
    }

    private var phase: Phase {
        switch presentation {
            case .information: .information
            case .progress: .progress
            case .status: .status
        }
    }

    private var indicatorTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .opacity.combined(with: .scale(scale: Self.transitionScale))
    }

    private func statusButton(_ status: DiscoveryAccessoryPresentation.Status) -> some View {
        Button {
            statusPopoverPresented = true
        } label: {
            Image(systemName: status.symbol)
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .foregroundStyle(status.color)
        .help(status.label)
        .accessibilityLabel(status.label)
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
            case .progress:
                infoPopoverPresented = false
                statusPopoverPresented = false
            case .status:
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
