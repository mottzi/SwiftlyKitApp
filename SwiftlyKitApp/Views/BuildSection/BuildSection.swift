import SwiftUI

struct BuildSection: View {
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        
        RoundedRectangle(cornerRadius: 12)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
    }
}
