import SwiftUI

@main struct SwiftlyKitApp: App {

    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .defaultSize(Constants.windowSize)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentMinSize)
    }
    
}
