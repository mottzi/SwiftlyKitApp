import SwiftlyKit
import Foundation

/// Current setup task or blocker shown before a package is ready to build.
struct BuildSetupStatus: Equatable {

    let title: String
    let detail: String
    var showsProgress = false
    var isInstalling = false
    var action: Action?

    /// Selects the first incomplete stage of package setup.
    static func current(
        host: HostDiscoveryState,
        toolchain: ToolchainDiscoveryState,
        product: ProductDiscoveryState
    ) -> Self {
        switch host {
            case .idle, .checking:
                return Self(title: "Checking developer tools", detail: "Preparing package setup.", showsProgress: true)
            case .commandLineToolsRequired:
                return Self(
                    title: "Command Line Tools required",
                    detail: "Install Apple's developer tools.",
                    action: .swiftDetails
                )
            case .requestingCommandLineTools:
                return Self(
                    title: "Opening installer",
                    detail: "Opening Apple's Command Line Tools installer.",
                    showsProgress: true
                )
            case .waitingForCommandLineTools:
                return Self(
                    title: "Finish installing developer tools",
                    detail: "Complete the installation, then check again.",
                    action: .swiftDetails
                )
            case .unsupported:
                return Self(
                    title: "Unsupported Mac",
                    detail: "SwiftlyKit requires Apple silicon and macOS 13 or later.",
                    action: .swiftDetails
                )
            case .failed(let detail):
                return Self(title: "Developer tools check failed", detail: detail, action: .swiftDetails)
            case .ready:
                break
        }

        switch toolchain {
            case .idle, .discovering:
                return Self(
                    title: "Checking Swift compatibility",
                    detail: "Inspecting the package and Swift releases.",
                    showsProgress: true
                )
            case .empty:
                return Self(
                    title: "No compatible Swift toolchains",
                    detail: "Review the package and target requirements.",
                    action: .swiftDetails
                )
            case .failed(let detail):
                return Self(title: "Swift compatibility check failed", detail: detail, action: .swiftDetails)
            case .ready:
                break
        }

        switch product {
            case .idle:
                return Self(
                    title: "Preparing build environment",
                    detail: "Preparing to inspect executable products.",
                    showsProgress: true
                )
            case .discovering(let detail, let installationTitle):
                return Self(
                    title: installationTitle ?? "Preparing build environment",
                    detail: detail,
                    showsProgress: true,
                    isInstalling: installationTitle != nil
                )
            case .installationRequired:
                return Self(
                    title: "Swift components required",
                    detail: "Review the required installation to continue.",
                    action: .reviewInstallation
                )
            case .empty:
                return Self(
                    title: "No executable products",
                    detail: "This package has no executable product to build."
                )
            case .failed(.swiftlyInstallationFailed(let detail)):
                return Self(title: "Tool installation failed", detail: detail, action: .productDetails)
            case .failed(let error):
                return Self(title: "Package inspection failed", detail: error.localizedDescription, action: .productDetails)
            case .ready:
                return Self(title: "Select an executable product", detail: "Choose a product in the Product menu.")
        }
    }

}

extension BuildSetupStatus {

    /// Existing recovery or detail action for the current setup blocker.
    enum Action {
        case swiftDetails
        case productDetails
        case reviewInstallation
    }

}

extension BuildSetupStatus.Action {

    /// Accessible label for the status row's action button.
    var label: String {
        switch self {
            case .swiftDetails, .productDetails: "Show Setup Details"
            case .reviewInstallation: "Review Installation"
        }
    }

    /// Symbol used within the existing status action slot.
    var symbol: String {
        switch self {
            case .swiftDetails, .productDetails: "info.circle"
            case .reviewInstallation: "arrow.down.circle"
        }
    }

}
