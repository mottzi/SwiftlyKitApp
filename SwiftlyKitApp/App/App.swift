import SwiftUI

@main struct SwiftlyKitApp: App {

    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .defaultSize(Self.defaultWindowSize)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentMinSize)
    }
    
}

extension SwiftlyKitApp {

    static let defaultWindowSize = CGSize(width: 500, height: 300)

}
