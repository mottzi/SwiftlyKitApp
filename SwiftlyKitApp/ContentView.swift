import SwiftUI
import SwiftlyKit

struct ContentView: View {

    @State private var packageURL: URL?

    private var isPackageSelected: Bool {
        packageURL != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProjectCard(packageURL: $packageURL)

            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.secondary)
        }
        .padding()
        .animation(.appSpring(response: 0.45, dampingFraction: 0.75), value: isPackageSelected)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // action
                } label: {
                    Label("Run", systemImage: "play.fill")
                }
                .tint(isPackageSelected ? .blue : nil)
                .disabled(!isPackageSelected)
            }
        }
    }

}

#Preview {
    ContentView()
        .frame(width: 500, height: 300)
}
