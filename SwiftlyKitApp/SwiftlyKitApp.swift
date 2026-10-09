import SwiftUI
import AppKit

@main
/// Build windows, update preferences, and the Help window.
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
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…", action: appDelegate.updater.checkForUpdates)
                    .disabled(!appDelegate.updater.canCheckForUpdates)
            }
            CommandGroup(replacing: .help) {
                Button("SwiftlyKitApp Help") {
                    openWindow(id: "help")
                }
            }
        }

        Settings {
            UpdateSettingsView(updater: appDelegate.updater)
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

/// App updates and termination after active work finishes.
final class AppDelegate: NSObject, NSApplicationDelegate {

    let activity: AppActivity
    let updater: AppUpdater
    private var terminationPending = false

    override init() {
        let activity = AppActivity()
        self.activity = activity
        updater = AppUpdater(activity: activity)
        super.init()
    }

    /// Starts updates for app launches outside tests and previews.
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        updater.start()
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
