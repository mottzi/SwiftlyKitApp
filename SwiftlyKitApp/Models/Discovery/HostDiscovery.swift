import Foundation
import Observation
import SwiftlyKit

/// Current host-readiness state for package discovery.
enum HostDiscoveryState: Equatable {

    /// No host inspection is active.
    case idle

    /// SwiftlyKit is inspecting the current host.
    case checking

    /// The host can run SwiftlyKit workflows.
    case ready

    /// The host needs Apple Command Line Tools before discovery can continue.
    case commandLineToolsRequired

    /// SwiftlyKit is asking macOS to open the Command Line Tools installer.
    case requestingCommandLineTools

    /// macOS accepted the installer request, but the tools are not ready yet.
    case waitingForCommandLineTools

    /// The current Mac cannot run SwiftlyKit workflows.
    case unsupported

    /// Host inspection or installer recovery failed.
    case failed(String)

}

@Observable
/// Inspects host readiness and coordinates Command Line Tools recovery.
final class HostDiscovery {

    /// Current host-readiness state.
    private(set) var state: HostDiscoveryState = .idle

    /// Whether the app should present Command Line Tools installation approval.
    private(set) var installationApprovalRequested = false

    /// Revision that requests another app-level host inspection task.
    private(set) var retryRevision = 0

    @ObservationIgnored private var installerWasRequested = false

    /// Inspects the host without changing developer tools state.
    func inspect() async {
        installationApprovalRequested = false
        state = .checking

        do {
            let readiness = try await SwiftlyKit.hostReadiness()

            guard !Task.isCancelled else { return }

            switch readiness {
                case .ready:
                    installerWasRequested = false
                    state = .ready
                case .developerToolsUnavailable:
                    handleUnavailableDeveloperTools()
                case .unsupportedHost:
                    state = .unsupported
            }
        } catch is CancellationError {
            // a replacement task owns the next state transition
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed("SwiftlyKit could not inspect the current host.")
        }
    }

    /// Requests approval to open Apple's Command Line Tools installer.
    func requestInstallationApproval() {
        installationApprovalRequested = true
    }

    /// Opens Apple's Command Line Tools installer and checks readiness again.
    func approveInstallation() async {
        guard installationApprovalRequested else { return }

        installationApprovalRequested = false
        state = .requestingCommandLineTools

        do {
            try await SwiftlyKit.requestCommandLineToolsInstallation()

            guard !Task.isCancelled else { return }

            installerWasRequested = true
            await inspect()
        } catch is CancellationError {
            // a replacement task owns the next state transition
        } catch let error as SwiftlyKitError {
            guard !Task.isCancelled else { return }

            if case .unsupportedHost = error {
                state = .unsupported
            } else {
                state = .failed(error.errorDescription ?? error.localizedDescription)
            }
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed("The Command Line Tools installer could not be opened.")
        }
    }

    /// Declines the pending Command Line Tools installer request.
    func cancelInstallation() {
        installationApprovalRequested = false
        state = installerWasRequested
            ? .waitingForCommandLineTools
            : .commandLineToolsRequired
    }

    /// Requests another host inspection through the existing app-level task.
    func requestRetry() {
        retryRevision += 1
    }

    /// Clears host readiness and installer recovery state.
    func clear() {
        state = .idle
        installationApprovalRequested = false
        installerWasRequested = false
    }

}

extension HostDiscovery {

    private func handleUnavailableDeveloperTools() {
        if installerWasRequested {
            state = .waitingForCommandLineTools
        } else {
            state = .commandLineToolsRequired
            installationApprovalRequested = true
        }
    }

}
