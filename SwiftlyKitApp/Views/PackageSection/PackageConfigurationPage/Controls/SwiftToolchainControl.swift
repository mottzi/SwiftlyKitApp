import SwiftUI
import SwiftlyKit

/// Swift toolchain selection and its state-dependent discovery feedback.
struct SwiftToolchainControl: View {

    @Environment(BuildOptions.self) private var buildOptions

    @Binding var infoPopoverPresented: Bool
    @Binding var statusPopoverPresented: Bool

    let onRetry: () -> Void

    var body: some View {
        @Bindable var buildOptions = buildOptions
        let discovery = buildOptions.toolchainDiscovery

        HStack(spacing: ConfigurationAccessoryMetrics.spacing) {
            ToolchainPicker(
                toolchain: $buildOptions.toolchain,
                availableToolchains: discovery.availableToolchains,
                discoveryState: discovery.state
            )

            DiscoveryAccessory(
                infoPopoverPresented: $infoPopoverPresented,
                statusPopoverPresented: $statusPopoverPresented,
                option: .swift,
                presentation: accessoryPresentation(for: discovery.state)
            ) {
                ToolchainDiscoveryStatusContent(
                    state: discovery.state,
                    onRetry: onRetry
                )
            }
        }
    }

    private func accessoryPresentation(
        for state: ToolchainDiscoveryState
    ) -> DiscoveryAccessoryPresentation {
        switch state {
            case .idle, .ready:
                return .information
            case .discovering:
                return .progress(
                    accessibilityLabel: "Discovering compatible Swift toolchains"
                )
            case .empty:
                return .status(
                    DiscoveryAccessoryPresentation.Status(
                        symbol: "info.circle",
                        color: .secondary,
                        label: "No compatible Swift toolchains"
                    )
                )
            case .failed:
                return .status(
                    DiscoveryAccessoryPresentation.Status(
                        symbol: "exclamationmark.triangle",
                        color: .orange,
                        label: "Toolchain discovery failed"
                    )
                )
        }
    }

}

/// Swift toolchain picker with labels for each discovery state.
private struct ToolchainPicker: View {

    @Binding var toolchain: ToolchainSelection

    let availableToolchains: [ToolchainSelection]
    let discoveryState: ToolchainDiscoveryState

    var body: some View {
        Picker(selection: $toolchain) {
            Text(ToolchainSelection.automatic.displayName)
                .tag(ToolchainSelection.automatic)

            ForEach(availableToolchains, id: \.self) { selection in
                Text(selection.displayName)
                    .tag(selection)
            }
        } label: {
            Text("Swift")
        } currentValueLabel: {
            Text(pickerLabel)
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .disabled(!allowsSelection)
    }

    private var pickerLabel: String {
        switch discoveryState {
            case .idle: "—"
            case .discovering: "Discovering…"
            case .ready: toolchain.displayName
            case .empty: "No Compatible Releases"
            case .failed: "Couldn’t Load"
        }
    }

    private var allowsSelection: Bool {
        if case .ready = discoveryState { return true }
        return false
    }

}

/// Contextual explanation for a toolchain discovery status.
private struct ToolchainDiscoveryStatusContent: View {

    let state: ToolchainDiscoveryState
    let onRetry: () -> Void

    var body: some View {
        switch state {
            case .empty:
                EmptyDiscoveryStatus(
                    title: "No compatible Swift toolchains",
                    message: "SwiftlyKit found no official stable Swift release compatible "
                        + "with this package and target.",
                    onRetry: onRetry
                )

            case .failed(let detail):
                FailedDiscoveryStatus(
                    title: "Couldn’t discover compatible Swift toolchains.",
                    detail: detail,
                    onRetry: onRetry
                )

            case .idle, .discovering, .ready:
                EmptyView()
        }
    }

}
