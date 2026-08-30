import SwiftUI
import SwiftlyKit

/// Stable build status and live console for the latest build workflow.
struct BuildSection: View {

    @Environment(PackageModel.self) private var packageModel
    @Environment(BuildOptions.self) private var buildOptions

    var body: some View {
        VStack(spacing: 0) {
            BuildStatus(
                state: buildOptions.buildWorkflow.state,
                result: buildOptions.buildWorkflow.result,
                readyDetail: readyDetail,
                onCancel: buildOptions.buildWorkflow.cancel
            )

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
        .deemphasiseContent(when: isWaitingForConfiguration)
    }

}

extension BuildSection {

    private var readyDetail: String? {
        guard let preparedPackage else { return nil }

        return "\(preparedPackage.selectedProduct.name) · \(buildOptions.target.displayName) · "
            + "\(buildOptions.configuration.displayName) · Swift \(preparedPackage.environment.swiftVersion)"
    }

    private var isWaitingForConfiguration: Bool {
        preparedPackage == nil && buildOptions.buildWorkflow.state == .idle
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
