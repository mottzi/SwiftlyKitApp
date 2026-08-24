import SwiftUI
import SwiftlyKit

struct PackageBuildDetails: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        VStack(alignment: .leading, spacing: 14) {
            Header()
            Divider().opacity(0.55)
            ConfigurationSection()
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary.opacity(0.38))
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

}

#Preview {
    AppView()
        .environment(AppState())
        .frame(width: 500, height: 300)
}
