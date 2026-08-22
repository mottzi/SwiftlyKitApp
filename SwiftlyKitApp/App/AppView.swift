import SwiftUI

struct AppView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        VStack(alignment: .leading, spacing: 16) {
            PackageSection()
            BuildSection()
        }
        .padding(.vertical)
        .toolbar { AppToolbar() }
    }
}

#Preview {
    AppView()
        .environment(AppState())
        .frame(width: 500, height: 300)
}

extension View {
    
    func debug(_ color: Color = .orange, _ width: CGFloat = 1) -> some View {
        self.border(color, width: width)
    }
}
