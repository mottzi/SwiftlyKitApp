import SwiftUI

@main struct SwiftlyKitApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appState)
        }
        .defaultSize(width: 700, height: 500)
    }
}
