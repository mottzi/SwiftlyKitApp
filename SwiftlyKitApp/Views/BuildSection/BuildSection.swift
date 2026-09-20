import SwiftUI
import SwiftlyKit

/// Current setup and build status with live console output.
struct BuildSection: View {

    @Environment(PackageModel.self) private var packageModel
    @Environment(BuildOptions.self) private var buildOptions

    @State private var setupDetailsPresented = false

    var body: some View {
        VStack(spacing: 0) {
            BuildStatus(
                state: buildOptions.buildWorkflow.state,
                result: buildOptions.buildWorkflow.result,
                isPublishing: buildOptions.buildWorkflow.isPublishing,
                readyDetail: readyDetail,
                setupStatus: setupStatus,
                onSetupAction: performSetupAction,
                onCancel: buildOptions.buildWorkflow.cancel,
                onExport: buildOptions.buildWorkflow.publishResult
            )
            .popover(isPresented: $setupDetailsPresented, arrowEdge: .trailing) {
                setupDetails
                    .padding()
                    .frame(width: 320, alignment: .leading)
            }
            .onChange(of: setupStatus) {
                setupDetailsPresented = false
            }

            Divider()
                .opacity(Self.dividerOpacity)

            BuildConsole(
                entries: buildOptions.buildWorkflow.log.entries,
                logRevision: buildOptions.buildWorkflow.log.revision,
                logText: buildOptions.buildWorkflow.log.text,
                onClear: buildOptions.buildWorkflow.log.clear
            )
        }
        .frame(
            minWidth: 0,
            idealWidth: 0,
            maxWidth: .infinity
        )
        .frame(
            minHeight: Self.minimumHeight,
            idealHeight: Self.minimumHeight,
            maxHeight: .infinity
        )
        .sectionSurface()
        .deemphasiseContent(when: !packageModel.isPackageSelected)
    }

}

extension BuildSection {

    private var readyDetail: String? {
        guard let preparedPackage else { return nil }

        return "\(preparedPackage.selectedProduct.name) · \(buildOptions.target.displayName) · "
            + "\(buildOptions.configuration.displayName) · Swift \(preparedPackage.environment.swiftVersion)"
    }

    private var setupStatus: BuildSetupStatus? {
        guard packageModel.isPackageSelected else { return nil }
        guard preparedPackage == nil else { return nil }

        return BuildSetupStatus.current(
            host: buildOptions.hostDiscovery.state,
            toolchain: buildOptions.toolchainDiscovery.state,
            product: buildOptions.productDiscovery.state
        )
    }

    private func performSetupAction() {
        switch setupStatus?.action {
            case .reviewInstallation:
                buildOptions.productDiscovery.requestInstallationApproval()
            case .swiftDetails, .productDetails:
                setupDetailsPresented = true
            case nil:
                break
        }
    }

    @ViewBuilder
    private var setupDetails: some View {
        if setupStatus?.action == .productDetails {
            ProductDiscoveryStatus(
                state: buildOptions.productDiscovery.state,
                onReviewInstallation: buildOptions.productDiscovery.requestInstallationApproval,
                onRetry: {
                    setupDetailsPresented = false
                    buildOptions.productDiscovery.requestRetry()
                }
            )
        } else {
            SwiftDiscoveryStatus(
                hostState: buildOptions.hostDiscovery.state,
                toolchainState: buildOptions.toolchainDiscovery.state,
                onRequestCommandLineTools: {
                    setupDetailsPresented = false
                    buildOptions.hostDiscovery.requestInstallationApproval()
                },
                onHostRetry: {
                    setupDetailsPresented = false
                    buildOptions.hostDiscovery.requestRetry()
                },
                onToolchainRetry: {
                    setupDetailsPresented = false
                    buildOptions.toolchainDiscovery.requestRetry()
                }
            )
        }
    }

    private var preparedPackage: PreparedPackage? {
        guard let packageRoot = packageModel.packageURL else { return nil }
        return buildOptions.preparedPackage(in: packageRoot)
    }

}

extension BuildSection {

    static let minimumHeight: CGFloat = 176
    private static let dividerOpacity = 0.55

}
