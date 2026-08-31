import SwiftUI

struct PackageActionsMenu: View {

    @Environment(PackageModel.self) private var packageModel
    @Environment(BuildOptions.self) private var buildOptions

    @State private var presentedAlert: PresentedAlert?

    var body: some View {

        Menu {
            if let url = packageModel.packageURL {
                Button("Show in Finder", systemImage: "folder") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }

                Button("Copy Path", systemImage: "doc.on.doc") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(
                        url.path(percentEncoded: false),
                        forType: .string
                    )
                }
            }

            Divider()

            Button("Clean Build Artifacts…", systemImage: "eraser") {
                presentedAlert = .cleanup(.cleanArtifacts)
            }
            .disabled(!canModifyBuildStorage)

            Button("Reset Build Storage…", systemImage: "trash") {
                presentedAlert = .cleanup(.resetStorage)
            }
            .disabled(!canModifyBuildStorage)

            Divider()

            Button("Close Package", systemImage: "xmark", role: .destructive) {
                closePackage()
            }
            .disabled(buildOptions.isOperationRunning)
        } label: {
            Image(
                systemName: buildOptions.buildStorageMaintenance.isRunning
                    ? "ellipsis.circle.fill"
                    : "ellipsis.circle"
            )
                .tint(Color.secondary.opacity(ConfigurationAccessoryMetrics.opacity))
                .foregroundStyle(Color.secondary.opacity(ConfigurationAccessoryMetrics.opacity))

        }
        .labelStyle(.iconOnly)
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .controlSize(.small)
        .help("Package actions")
        .accessibilityLabel("Package actions")
        .alert(
            presentedAlert?.title ?? "Build Storage",
            isPresented: alertPresented,
            presenting: presentedAlert
        ) { alert in
            switch alert {
                case .cleanup(let cleanup):
                    Button(cleanup.confirmationButtonTitle, role: .destructive) {
                        start(cleanup)
                    }
                    Button("Cancel", role: .cancel) { }
                case .failure:
                    Button("OK") { }
            }
        } message: { alert in
            Text(alert.message(for: packageModel.packageName))
        }
    }

}

extension PackageActionsMenu {

    private var canModifyBuildStorage: Bool {
        guard !buildOptions.isOperationRunning else { return false }
        guard let packageRoot = packageModel.packageURL else { return false }
        return buildOptions.preparedPackage(in: packageRoot) != nil
    }

    private var alertPresented: Binding<Bool> {
        Binding(
            get: { presentedAlert != nil },
            set: { isPresented in
                if !isPresented {
                    presentedAlert = nil
                }
            }
        )
    }

    private func start(_ cleanup: BuildStorageCleanup) {
        guard let packageRoot = packageModel.packageURL else { return }

        Task {
            do {
                try await buildOptions.performCleanup(cleanup, in: packageRoot)
            } catch is CancellationError {
                // The cancelled task no longer owns presentation state.
            } catch {
                presentedAlert = .failure(error.localizedDescription)
            }
        }
    }

    private func closePackage() {
        guard !buildOptions.isOperationRunning else { return }

        buildOptions.clearPackageSession()
        withAnimation {
            packageModel.clearPackage()
        }
    }

}

extension PackageActionsMenu {

    private enum PresentedAlert: Equatable {
        case cleanup(BuildStorageCleanup)
        case failure(String)

        var title: String {
            switch self {
                case .cleanup(.cleanArtifacts): "Clean Build Artifacts?"
                case .cleanup(.resetStorage): "Reset Build Storage?"
                case .failure: "Build Storage Cleanup Failed"
            }
        }

        func message(for packageName: String) -> String {
            switch self {
                case .cleanup(.cleanArtifacts):
                    "This removes compiled products and intermediates for \(packageName). "
                        + "Package dependency state is retained."
                case .cleanup(.resetStorage):
                    "This removes all SwiftPM build storage for \(packageName), including package dependency state."
                case .failure(let failure):
                    failure
            }
        }
    }

}

extension BuildStorageCleanup {

    fileprivate var confirmationButtonTitle: String {
        switch self {
            case .cleanArtifacts: "Clean"
            case .resetStorage: "Reset"
        }
    }

}
