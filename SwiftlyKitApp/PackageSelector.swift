import SwiftUI
import UniformTypeIdentifiers

struct PackageSelector: View {

    @Environment(AppState.self) private var appState

    @State private var isFileImporterPresented = false
    @State private var isDropTargeted = false

    var body: some View {
        Button {
            if !appState.isPackageSelected {
                isFileImporterPresented = true
            }
        } label: {
            Container()
        }
        .buttonStyle(SelectorButtonStyle())
        .environment(\.isDropTargeted, isDropTargeted)
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                Task { @MainActor in
                    await Task.yield()
                    handleSelection(url)
                }
            }
        }
        .dropDestination(for: URL.self) { items, session in
            guard let url = items.first else { return }
            handleSelection(url)
        }
        .onDropSessionUpdated { session in
            isDropTargeted = switch session.phase {
                case .entering, .active: true
                default: false
            }
        }
    }

    private func handleSelection(_ url: URL) {
        withAnimation {
            appState.selectPackage(at: url)
        }
    }

}

// MARK: - Subviews

private extension PackageSelector {

    struct SelectorButtonStyle: ButtonStyle {
        @Environment(AppState.self) private var appState
        @Environment(\.isDropTargeted) private var isDropTargeted
        @State private var isHovering = false

        func makeBody(configuration: Configuration) -> some View {
            let isPressed = !appState.isPackageSelected && configuration.isPressed
            let isHover = !appState.isPackageSelected && isHovering

            let backgroundOpacity = if isPressed {
                0.10
            } else if isDropTargeted {
                0.12
            } else if isHover {
                0.04
            } else {
                0.0
            }

            let containerScale = if isPressed {
                0.98
            } else if isDropTargeted {
                1.02
            } else {
                1.0
            }

            return configuration.label
                .environment(\.isHovering, isHover)
                .environment(\.isPressed, isPressed)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(backgroundOpacity))
                )
                .scaleEffect(containerScale)
                .animation(.default, value: isDropTargeted)
                .animation(.default, value: isHover)
                .animation(.default, value: isPressed)
                .onHover { isHovering = $0 }
        }
    }

    struct Container: View {
        @Environment(AppState.self) private var appState
        @Environment(\.isHovering) private var isHovering
        @Environment(\.isPressed) private var isPressed
        @Environment(\.isDropTargeted) private var isDropTargeted

        private var strokeColor: Color {
            isDropTargeted || (!appState.isPackageSelected && isHovering) ? .orange : .secondary
        }

        private var lineWidth: CGFloat {
            if appState.isPackageSelected { 0 }
            else { isDropTargeted ? 3 : 2 }
        }

        var body: some View {
            
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    strokeColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        dash: isDropTargeted ? [10, 6] : [8, 6],
                        dashPhase: isDropTargeted ? -12 : (isHovering ? (isPressed ? -12 : -6) : 0)
                    )
                )
                .opacity(appState.isPackageSelected ? 0 : 1)
                .overlay { Content() }
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .animation(.default, value: isDropTargeted)
                .animation(.default, value: isHovering)
                .animation(.default, value: isPressed)
                .animation(.default, value: appState.isPackageSelected)
        }
    }

    struct Content: View {
        @Environment(AppState.self) private var appState

        var body: some View {
            ZStack {
                if appState.isPackageSelected {
                    SelectedPackageScaffold()
                        .transition(.opacity)
                } else {
                    DropzoneContent()
                        .transition(.opacity)
                }
            }
        }
    }

    struct DropzoneContent: View {
        var body: some View {
            HStack(spacing: 16) {
                Icon()
                Label()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.rect)
            .padding(12)
        }
    }

    struct SelectedPackageScaffold: View {
        @Environment(AppState.self) private var appState

        var body: some View {
            EmptyView()
        }
    }

    struct Icon: View {
        @Environment(\.isHovering) private var isHovering
        @Environment(\.isPressed) private var isPressed
        @Environment(\.isDropTargeted) private var isDropTargeted

        private var iconScale: CGFloat {
            if isPressed {
                0.96
            } else if isDropTargeted {
                1.10
            } else {
                1.0
            }
        }

        private var iconRotation: Angle {
            if isDropTargeted {
                .degrees(0)
            } else if isHovering {
                .degrees(isPressed ? 2 : 4)
            } else {
                .degrees(0)
            }
        }

        var body: some View {
            Image(systemName: "swift")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .rotationEffect(iconRotation)
                .scaleEffect(iconScale)
                .foregroundStyle(isDropTargeted || isHovering ? .orange : .secondary)
                .animation(.default, value: isDropTargeted)
                .animation(.default, value: isHovering)
                .animation(.default, value: isPressed)
        }
    }

    struct Label: View {
        @Environment(\.isHovering) private var isHovering
        @Environment(\.isDropTargeted) private var isDropTargeted
        
        var labelText: String {
            if isHovering {
                "Select Package"
            } else {
                "Drop Package here"
            }
        }
        
        var body: some View {
            ZStack(alignment: .leading) {
                Text("Drop Package here").hidden()
                Text("Select Package").hidden()
                Text("Drop to Select").hidden()
                Text(labelText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .font(.largeTitle)
            .fontWeight(isDropTargeted ? .medium : .light)
            .foregroundStyle(isDropTargeted ? .orange : (isHovering ? .primary : .secondary))
            .animation(.default, value: isDropTargeted)
            .animation(.default, value: isHovering)
        }
    }
    
}

extension EnvironmentValues {
    @Entry var isHovering = false
    @Entry var isPressed = false
    @Entry var isDropTargeted = false
}

#Preview {
    ContentView()
        .environment(AppState())
        .frame(width: 500, height: 300)
}
