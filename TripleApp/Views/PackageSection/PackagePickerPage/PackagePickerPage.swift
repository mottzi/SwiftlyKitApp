import SwiftUI
import UniformTypeIdentifiers

/// Selects a package folder or its manifest with the system importer or drag and drop.
struct PackagePickerPage: View {

    @Environment(PackageModel.self) private var packageModel

    @State private var invalidPackageName: String?
    @State private var isFileImporterPresented = false
    @State private var isDropTargeted = false
    @State private var isHovering = false

    let arrangement: AdaptiveGridArrangement

    private var canSelect: Bool {
        !packageModel.isPackageSelected
    }

    private var showsHover: Bool {
        canSelect && isHovering
    }

    private var isDropTargetedForPresentation: Bool {
        canSelect && isDropTargeted
    }

    var body: some View {
        Button {
            isFileImporterPresented = true
        } label: {
            PackagePickerLabel(
                showsHover: showsHover,
                isDropTargeted: isDropTargetedForPresentation,
                arrangement: arrangement
            )
        }
        .buttonStyle(
            PackagePickerStyle(
                isDropTargeted: isDropTargetedForPresentation,
                showsHover: showsHover,
                canSelect: canSelect
            )
        )
        .disabled(!canSelect)
        .onHover {
            isHovering = $0
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.folder, .swiftSource]
        ) { result in
            guard case .success(let url) = result else { return }
            selectPackage(at: url)
        }
        .alert(
            "Invalid Package Selection",
            isPresented: invalidPackageAlertPresented,
            presenting: invalidPackageName
        ) { _ in
            Button("Choose Again…") {
                isFileImporterPresented = true
            }
            Button("Cancel", role: .cancel) { }
        } message: { packageName in
            Text("“\(packageName)” is not a package folder or a Package.swift file. " +
                 "Choose a folder containing Package.swift, or the Package.swift file itself.")
        }
        .dropDestination(for: URL.self, isEnabled: canSelect) { items, _ in
            guard let url = items.first else { return }
            selectPackage(at: url)
        }
        .onDropSessionUpdated { session in
            let isTargeted = switch session.phase {
                case .entering, .active: true
                default: false
            }
            isDropTargeted = canSelect && isTargeted
        }
    }

}

extension PackagePickerPage {

    private var invalidPackageAlertPresented: Binding<Bool> {
        Binding(
            get: { invalidPackageName != nil },
            set: { isPresented in
                if !isPresented {
                    invalidPackageName = nil
                }
            }
        )
    }

    private func selectPackage(at url: URL) {

        withAnimation(.default, completionCriteria: .removed) {
            packageModel.selectPackage(at: url)
        } completion: {
            packageModel.finishConfigurationTransition()
        }

        guard packageModel.isPackageSelected else {
            invalidPackageName = url.lastPathComponent
            return
        }
    }

}
