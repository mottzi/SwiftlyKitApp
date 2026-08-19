import SwiftUI
import SwiftlyKit

struct ContentView: View {

    @State private var isPackageSelected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PackageSelector()
            
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.secondary)
                .frame(maxHeight: .infinity)
        }
        .padding()
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
