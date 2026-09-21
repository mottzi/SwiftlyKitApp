import Foundation
import SwiftUI
import SwiftlyKit

#Preview("Package and build header states") {
    AppPreview()
}

private struct AppPreview: View {

    @State private var disabledPackageModel: PackageModel
    @State private var disabledBuildOptions: BuildOptions
    @State private var enabledPackageModel: PackageModel
    @State private var enabledBuildOptions: BuildOptions

    init() {
        _disabledPackageModel = State(initialValue: Self.makePackageModel())
        _disabledBuildOptions = State(initialValue: BuildOptions())
        _enabledPackageModel = State(initialValue: Self.makePackageModel())
        _enabledBuildOptions = State(initialValue: BuildOptions())
    }

    var body: some View {
        BuildSectionHeaderPreview(
            disabledPackageModel: disabledPackageModel,
            disabledBuildOptions: disabledBuildOptions,
            enabledPackageModel: enabledPackageModel,
            enabledBuildOptions: enabledBuildOptions
        )
    }

}

extension AppPreview {

    private static func makePackageModel() -> PackageModel {
        let model = PackageModel()
        model.selectPackage(at: packageURL)
        model.finishConfigurationTransition()
        return model
    }

    private static let packageURL = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: "Development/Swift/SwiftlyKit/Tests/SwiftlyKitTests/Fixtures/CrossCompilationPackage")
}

private struct BuildSectionHeaderPreview: View {

    private let disabledPackageModel: PackageModel
    private let disabledBuildOptions: BuildOptions
    private let enabledPackageModel: PackageModel
    private let enabledBuildOptions: BuildOptions

    init(
        disabledPackageModel: PackageModel,
        disabledBuildOptions: BuildOptions,
        enabledPackageModel: PackageModel,
        enabledBuildOptions: BuildOptions
    ) {
        self.disabledPackageModel = disabledPackageModel
        self.disabledBuildOptions = disabledBuildOptions
        self.enabledPackageModel = enabledPackageModel
        self.enabledBuildOptions = enabledBuildOptions
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                packageHeader(
                    title: "Package header, build button disabled",
                    packageModel: disabledPackageModel,
                    buildOptions: disabledBuildOptions
                )

                packageHeader(
                    title: "Package header, build button enabled",
                    packageModel: enabledPackageModel,
                    buildOptions: enabledBuildOptions
                )

                ForEach(Self.states) { state in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        header(for: state)
                    }
                }
            }
            .padding(Self.previewPadding)
        }
        .frame(width: 520, height: 620)
        .background(.quaternary.opacity(0.35))
    }

}

extension BuildSectionHeaderPreview {

    private func packageHeader(title: String, packageModel: PackageModel, buildOptions: BuildOptions) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            PackageHeader()
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 14)
                .sectionSurface()
                .environment(packageModel)
                .environment(buildOptions)
        }
    }

    private func header(for state: State) -> some View {
        BuildStatus(
            state: state.workflowState,
            result: nil,
            isPublishing: false,
            readyDetail: state.readyDetail,
            onCancel: {},
            onExport: { _ in nil }
        )
            .frame(
                minWidth: 0,
                idealWidth: 0,
                maxWidth: .infinity,
                minHeight: 48,
                idealHeight: 48
            )
            .sectionSurface()
            .deemphasiseContent(when: state.isWaitingForConfiguration)
    }

}

extension BuildSectionHeaderPreview {

    private struct State: Identifiable {

        let id: String
        let title: String
        let workflowState: BuildWorkflowState
        let readyDetail: String?

        init(
            id: String,
            title: String,
            workflowState: BuildWorkflowState,
            readyDetail: String?
        ) {
            self.id = id
            self.title = title
            self.workflowState = workflowState
            self.readyDetail = readyDetail
        }

        var isWaitingForConfiguration: Bool {
            readyDetail == nil && workflowState == .idle
        }

    }

}

extension BuildSectionHeaderPreview {

    private static let previewPadding: CGFloat = 12

    private static let states: [State] = [
        State(
            id: "idle-waiting",
            title: "Idle, waiting for package discovery",
            workflowState: .idle,
            readyDetail: nil
        ),
        State(
            id: "idle-ready",
            title: "Idle, ready to build",
            workflowState: .idle,
            readyDetail: "Example · x86_64 · release · Swift 6.2.1"
        ),
        State(
            id: "active-building",
            title: "Active, building",
            workflowState: .active(
                phase: .building,
                detail: "Compiling Example."
            ),
            readyDetail: nil
        ),
        State(
            id: "active-resolving-dependencies",
            title: "Active, resolving dependencies",
            workflowState: .active(
                phase: .resolvingDependencies,
                detail: "Resolving package dependencies."
            ),
            readyDetail: nil
        ),
        State(
            id: "active-stripping",
            title: "Active, stripping executable",
            workflowState: .active(
                phase: .stripping,
                detail: "Stripping executable."
            ),
            readyDetail: nil
        ),
        State(
            id: "cancelling",
            title: "Cancelling",
            workflowState: .cancelling,
            readyDetail: nil
        ),
        State(
            id: "succeeded",
            title: "Succeeded",
            workflowState: .succeeded,
            readyDetail: nil
        ),
        State(
            id: "failed",
            title: "Failed",
            workflowState: .failed("The selected product could not be built."),
            readyDetail: nil
        ),
        State(
            id: "cancelled",
            title: "Cancelled",
            workflowState: .cancelled,
            readyDetail: nil
        )
    ]

}
