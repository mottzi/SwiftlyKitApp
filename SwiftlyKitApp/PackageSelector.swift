import SwiftUI

struct PackageSelector: View {

    var body: some View {
        Button {

        } label: {
            Border()
        }
        .buttonStyle(SelectorButtonStyle())
    }

}

// MARK: - Subviews

private extension PackageSelector {
    
    struct Border: View {
        @Environment(\.isHovering) private var isHovering
        @Environment(\.isPressed) private var isPressed
        
        var body: some View {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(
                        lineWidth: 2,
                        dash: [8, 6],
                        dashPhase: isHovering ? (isPressed ? -12 : -6) : 0
                    )
                )
                .foregroundStyle(isHovering ? .orange : .secondary)
                .frame(maxHeight: .infinity)
                .overlay { Content() }
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .animation(.spring(response: 0.3, dampingFraction: 0.7).speed(0.8), value: isHovering)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
    }
    
    struct Content: View {
        var body: some View {
            HStack(spacing: 16) {
                Icon()
                Label()
            }
        }
    }
    
    struct Icon: View {
        @Environment(\.isHovering) private var isHovering
        @Environment(\.isPressed) private var isPressed
        
        var body: some View {
            Image(systemName: "swift")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(isHovering ? (isPressed ? 2 : 4) : 0))
                .scaleEffect(isPressed ? 0.96 : 1.0)
                .foregroundStyle(isHovering ? .orange : .secondary)
        }
    }
    
    struct Label: View {
        @Environment(\.isHovering) private var isHovering
        
        var labelText: String {
            isHovering
            ? "Select Package"
            : "Drop Package here"
        }
        
        var body: some View {
            ZStack(alignment: .leading) {
                Text("Drop Package here").hidden()
                Text("Select Package").hidden()
                Text(labelText)
            }
            .font(.largeTitle)
            .fontWeight(.light)
            .foregroundStyle(isHovering ? .primary : .secondary)
        }
    }
    
}

private extension PackageSelector {

    struct SelectorButtonStyle: ButtonStyle {
        @State private var isHovering = false

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .environment(\.isHovering, isHovering)
                .environment(\.isPressed, configuration.isPressed)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(configuration.isPressed ? 0.1 : (isHovering ? 0.04 : 0.0)))
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
                .onHover { isHovering = $0 }
        }
    }

}

extension EnvironmentValues {
    @Entry var isHovering = false
    @Entry var isPressed = false
}

#Preview {
    ContentView()
        .frame(width: 500, height: 300)
}
