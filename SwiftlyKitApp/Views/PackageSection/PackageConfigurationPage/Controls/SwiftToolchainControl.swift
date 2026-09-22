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
        let hostDiscovery = buildOptions.hostDiscovery
        let discovery = buildOptions.toolchainDiscovery

        HStack(spacing: ConfigurationAccessoryMetrics.spacing) {
            ToolchainPicker(
                toolchain: $buildOptions.toolchain,
                availableToolchains: discovery.availableToolchains,
                allowsSelection: allowsSelection(
                    for: hostDiscovery.state,
                    discoveryState: discovery.state
                )
            )

            DiscoveryAccessory(
                infoPopoverPresented: $infoPopoverPresented,
                statusPopoverPresented: $statusPopoverPresented,
                option: .swift,
                presentation: accessoryPresentation(
                    for: hostDiscovery.state,
                    discoveryState: discovery.state
                )
            ) {
                SwiftDiscoveryStatus(
                    hostState: hostDiscovery.state,
                    toolchainState: discovery.state,
                    onRequestCommandLineTools: hostDiscovery.requestInstallationApproval,
                    onHostRetry: hostDiscovery.requestRetry,
                    onToolchainRetry: onRetry
                )
            }
        }
    }

}

extension SwiftToolchainControl {

    private func accessoryPresentation(
        for hostState: HostDiscoveryState,
        discoveryState: ToolchainDiscoveryState
    ) -> DiscoveryAccessoryPresentation {
        switch hostState {
            case .idle:
                return .information
            case .checking:
                return .progress(accessibilityLabel: "Checking developer tools")
            case .ready:
                return toolchainAccessoryPresentation(for: discoveryState)
            case .commandLineToolsRequired:
                return .status(
                    DiscoveryAccessoryPresentation.Status(
                        symbol: "wrench.and.screwdriver",
                        color: .secondary,
                        label: "Command Line Tools required"
                    )
                )
            case .requestingCommandLineTools:
                return .progress(accessibilityLabel: "Opening Command Line Tools installer")
            case .waitingForCommandLineTools:
                return .status(
                    DiscoveryAccessoryPresentation.Status(
                        symbol: "clock.arrow.circlepath",
                        color: .secondary,
                        label: "Waiting for Command Line Tools"
                    )
                )
            case .unsupported:
                return .status(
                    DiscoveryAccessoryPresentation.Status(
                        symbol: "exclamationmark.triangle",
                        color: .orange,
                        label: "Unsupported Mac"
                    )
                )
            case .failed:
                return .status(
                    DiscoveryAccessoryPresentation.Status(
                        symbol: "exclamationmark.triangle",
                        color: .orange,
                        label: "Developer tools inspection failed"
                    )
                )
        }
    }

    private func toolchainAccessoryPresentation(for state: ToolchainDiscoveryState) -> DiscoveryAccessoryPresentation {
        switch state {
            case .idle:
                return .progress(
                    accessibilityLabel: "Starting compatible Swift toolchain discovery"
                )
            case .ready:
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

    private func allowsSelection(for hostState: HostDiscoveryState, discoveryState: ToolchainDiscoveryState) -> Bool {
        guard case .ready = hostState else { return false }
        if case .ready = discoveryState { return true }
        return false
    }

}

/// Swift toolchain picker that displays only toolchain choices.
private struct ToolchainPicker: View {

    @Binding var toolchain: ToolchainSelection

    let availableToolchains: [ToolchainSelection]
    let allowsSelection: Bool

    var body: some View {
        Picker(selection: $toolchain) {
            Text(ToolchainSelection.automatic.displayName)
                .tag(ToolchainSelection.automatic)

            if toolchain != .automatic, !availableToolchains.contains(toolchain) {
                Text(toolchain.displayName)
                    .tag(toolchain)
                    .disabled(true)
            }

            ForEach(availableToolchains, id: \.self) { selection in
                Text(selection.displayName)
                    .tag(selection)
            }
        } label: {
            Text("Swift")
        } currentValueLabel: {
            Text(toolchain.displayName)
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .disabled(!allowsSelection)
    }

}
