import SwiftUI
import UniformTypeIdentifiers

struct PackagePicker: View {

    @Environment(AppState.self) private var appState
    
    @State private var isDropTargeted = false
    @State private var isHovering = false
    
    private var canSelect: Bool {
        !appState.isPackageSelected
    }
    
    private var showsHover: Bool {
        canSelect && isHovering
    }

    var body: some View {
        @Bindable var appState = appState

        Button {
            guard canSelect else { return }
            appState.isFileImporterPresented = true
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
            isPresented: $appState.isFileImporterPresented,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                Task {
                    await Task.yield()
                    withAnimation {
                        appState.selectPackage(at: url)
                    }
                }
            }
        }
        .dropDestination(for: URL.self) { items, session in
            guard let url = items.first else { return }
            withAnimation {
                appState.selectPackage(at: url)
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

#Preview {
    AppView()
        .environment(AppState())
        .frame(width: 500, height: 300)
}
