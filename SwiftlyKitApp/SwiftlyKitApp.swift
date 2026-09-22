import SwiftUI

@main
/// Build windows and the Help window opened from the application menu.
struct SwiftlyKitApp: App {

    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .defaultSize(width: 500, height: 420)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .help) {
                Button("SwiftlyKitApp Help") {
                    openWindow(id: "help")
                }
            }
        }

        Window("SwiftlyKitApp Help", id: "help") {
            HelpView()
        }
        .defaultSize(width: 480, height: 560)
        .windowResizability(.contentMinSize)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
    }

}
