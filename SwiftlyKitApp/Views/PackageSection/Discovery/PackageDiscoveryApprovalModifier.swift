import SwiftlyKit
import SwiftUI

/// Presents installation approvals requested by package discovery.
struct PackageDiscoveryApprovalModifier: ViewModifier {

    @State private var approvalPresented = false
    @State private var presentedApproval: DiscoveryApproval?

    let buildOptions: BuildOptions

    func body(content: Content) -> some View {
        content
            .onChange(
                of: buildOptions.hostDiscovery.installationApprovalRequested,
                initial: true
            ) {
                presentPendingApproval()
            }
            .onChange(
                of: buildOptions.productDiscovery.installationApprovalRevision,
                initial: true
            ) {
                presentPendingApproval()
            }
            .alert(
                approvalTitle,
                isPresented: $approvalPresented
            ) {
                approvalActions
            } message: {
                Text(approvalMessage)
            }
    }

}

extension PackageDiscoveryApprovalModifier {

    @ViewBuilder
    private var approvalActions: some View {
        switch presentedApproval {
            case .commandLineTools:
                Button("Open Installer") {
                    Task {
                        await buildOptions.hostDiscovery.approveInstallation()
                    }
                }
                .keyboardShortcut(.defaultAction)

                Button("Cancel", role: .cancel) {
                    buildOptions.hostDiscovery.cancelInstallation()
                }

            case .components:
                Button("Install") {
                    buildOptions.productDiscovery.approveInstallation()
                }
                .keyboardShortcut(.defaultAction)

                Button("Cancel", role: .cancel) {
                    buildOptions.cancelInstallation()
                }

            case nil:
                EmptyView()
        }
    }

    private func presentPendingApproval() {
        if buildOptions.hostDiscovery.installationApprovalRequested {
            presentedApproval = .commandLineTools
            approvalPresented = true
        } else if case .installationRequired(let approval) = buildOptions.productDiscovery.state {
            presentedApproval = .components(approval)
            approvalPresented = true
        } else {
            approvalPresented = false
            presentedApproval = nil
        }
    }

    private var approvalTitle: String {
        switch presentedApproval {
            case .commandLineTools: "Install Command Line Tools?"
            case .components, nil: "Install required tools?"
        }
    }

    private var approvalMessage: String {
        switch presentedApproval {
            case .commandLineTools:
                "SwiftlyKit needs Apple Command Line Tools before it can discover compatible Swift releases."
            case .components(let approval):
                approval.message
            case nil:
                ""
        }
    }

}

extension PackageDiscoveryApprovalModifier {

    private enum DiscoveryApproval: Equatable {
        case commandLineTools
        case components(InstallationApprovalRequest)
    }

}
