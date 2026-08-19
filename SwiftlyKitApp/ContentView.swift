import SwiftUI
import SwiftlyKit

struct ContentView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SwiftlyKit")
                .font(.title.bold())
                .accessibilityIdentifier("appTitle")
            
        }
    }

}

#Preview {
    ContentView()
}
