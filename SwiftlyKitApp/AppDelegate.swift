import AppKit

/// Application termination after the final window closes.
final class AppDelegate: NSObject, NSApplicationDelegate {

    /// Returns permission to terminate after the final window closes.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

}
