import SwiftUI

/// Host-readiness details and recovery actions for the Swift accessory.
struct HostDiscoveryStatus: View {

    let state: HostDiscoveryState
    let onRequestInstallation: () -> Void
    let onRetry: () -> Void

    var body: some View {
        switch state {
            case .checking:
                DiscoveryProgressStatus(
                    title: "Checking developer tools",
                    detail: "SwiftlyKit is checking whether this Mac can run package workflows."
                )

            case .commandLineToolsRequired:
                commandLineToolsRequired

            case .requestingCommandLineTools:
                DiscoveryProgressStatus(
                    title: "Opening Command Line Tools installer",
                    detail: "SwiftlyKit is asking macOS to open Apple's installer."
                )

            case .waitingForCommandLineTools:
                waitingForCommandLineTools

            case .unsupported:
                unsupportedHost

            case .failed(let detail):
                FailedDiscoveryStatus(
                    title: "Couldn’t inspect developer tools.",
                    detail: detail,
                    onRetry: onRetry
                )

            case .idle, .ready:
                EmptyView()
        }
    }

}

extension HostDiscoveryStatus {

    private var commandLineToolsRequired: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Command Line Tools required")
                .font(.headline)

            Text("SwiftlyKit needs Apple Command Line Tools before it can discover compatible Swift releases.")
                .fixedSize(horizontal: false, vertical: true)

            Button("Open Installer…", action: onRequestInstallation)
                .keyboardShortcut(.defaultAction)
        }
    }

    private var waitingForCommandLineTools: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Finish installing Command Line Tools")
                .font(.headline)

            Text("Complete the installation in the macOS installer, then check again.")
                .fixedSize(horizontal: false, vertical: true)

            Button("Check Again", action: onRetry)
                .keyboardShortcut(.defaultAction)
        }
    }

    private var unsupportedHost: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unsupported Mac")
                .font(.headline)

            Text("SwiftlyKit requires Apple silicon and macOS 13 or later.")
                .fixedSize(horizontal: false, vertical: true)
        }
    }

}
