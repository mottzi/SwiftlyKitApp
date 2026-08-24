import SwiftUI
import UniformTypeIdentifiers

struct PackagePicker: View {

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
            PickerLabel(
                showsHover: showsHover,
                isDropTargeted: isDropTargetedForPresentation
            )
        }
        .buttonStyle(
            PickerStyle(
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
            if case .success(let url) = result {
                Task {
                    await Task.yield()
                    withAnimation {
                        packageModel.selectPackage(at: url)
                    }
                }
            }
        }
        .dropDestination(for: URL.self, isEnabled: canSelect) { items, _ in
            guard let url = items.first else { return }
            withAnimation {
                packageModel.selectPackage(at: url)
            }
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
