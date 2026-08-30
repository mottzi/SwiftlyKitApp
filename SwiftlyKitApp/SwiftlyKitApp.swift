import SwiftUI

@main
struct SwiftlyKitApp: App {

    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .defaultSizeAtMinimumHeight(width: Self.defaultWindowWidth)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentMinSize)
    }

}

extension SwiftlyKitApp {

    static let defaultWindowWidth: CGFloat = 500

}
