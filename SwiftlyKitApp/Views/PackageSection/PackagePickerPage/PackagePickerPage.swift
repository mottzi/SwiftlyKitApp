import SwiftUI
import UniformTypeIdentifiers

struct PackagePickerPage: View {

    @Environment(PackageModel.self) private var packageModel

    @State private var isFileImporterPresented = false
    @State private var isDropTargeted = false
    @State private var isHovering = false

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
                isDropTargeted: isDropTargetedForPresentation
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
            allowedContentTypes: [.folder]
        ) { result in
            guard case .success(let url) = result else { return }
            selectPackage(at: url)
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

    private func selectPackage(at url: URL) {
        withAnimation {
            packageModel.selectPackage(at: url)
        }
    }

}
