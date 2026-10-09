import SwiftUI
import AppKit

@main
/// Build windows and the Help window opened from the application menu.
struct SwiftlyKitApp: App {

    @Environment(\.openWindow) private var openWindow

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppView(activity: appDelegate.activity)
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

/// Application termination after active work finishes.
final class AppDelegate: NSObject, NSApplicationDelegate {

    let activity: AppActivity
    private var terminationPending = false

    override init() {
        let activity = AppActivity()
        self.activity = activity
        super.init()
    }

    /// Delays termination until active operations finish, including updates installed on quit.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {

        guard activity.isBusy else { return .terminateNow }
        if !terminationPending {
            terminationPending = true
            activity.whenIdle { [weak self, weak sender] in
                self?.terminationPending = false
                sender?.reply(toApplicationShouldTerminate: true)
            }
        }
        return .terminateLater
    }

    /// Returns permission to terminate after the final window closes.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

}
