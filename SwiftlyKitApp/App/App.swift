import SwiftUI

@main struct SwiftlyKitApp: App {

    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .defaultSize(width: 500, height: 300)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentMinSize)
    }
    
}
