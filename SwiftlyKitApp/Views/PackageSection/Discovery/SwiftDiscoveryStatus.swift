import SwiftUI

/// Contextual explanation for host or toolchain discovery status.
struct SwiftDiscoveryStatus: View {

    let hostState: HostDiscoveryState
    let toolchainState: ToolchainDiscoveryState
    let onRequestCommandLineTools: () -> Void
    let onHostRetry: () -> Void
    let onToolchainRetry: () -> Void

    var body: some View {
        if case .ready = hostState {
            ToolchainDiscoveryStatus(
                state: toolchainState,
                onRetry: onToolchainRetry
            )
        } else {
            HostDiscoveryStatus(
                state: hostState,
                onRequestInstallation: onRequestCommandLineTools,
                onRetry: onHostRetry
            )
        }
    }

}

/// Contextual explanation for a toolchain discovery status.
private struct ToolchainDiscoveryStatus: View {

    let state: ToolchainDiscoveryState
    let onRetry: () -> Void

    var body: some View {
        switch state {
            case .idle:
                DiscoveryProgressStatus(
                    title: "Starting compatible Swift release discovery",
                    detail: "SwiftlyKit is preparing to inspect the selected package."
                )

            case .discovering:
                DiscoveryProgressStatus(
                    title: "Discovering compatible Swift releases",
                    detail: "SwiftlyKit is inspecting the package and official Swift release catalog."
                )

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

            case .ready:
                EmptyView()
        }
    }

}
