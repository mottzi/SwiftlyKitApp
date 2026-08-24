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

    var body: some View {
        Button {
            guard canSelect else { return }
            isFileImporterPresented = true
        } label: {
            PickerLabel(
                showsHover: showsHover,
                isDropTargeted: isDropTargeted
            )
        }
        .buttonStyle(
            PickerStyle(
                isDropTargeted: isDropTargeted,
                showsHover: showsHover,
                canSelect: canSelect
            )
        )
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
        .dropDestination(for: URL.self) { items, session in
            guard let url = items.first else { return }
            withAnimation {
                packageModel.selectPackage(at: url)
            }
        }
        .onDropSessionUpdated { session in
            isDropTargeted = switch session.phase {
                case .entering, .active: true
                default: false
            }
        }
    }

}
