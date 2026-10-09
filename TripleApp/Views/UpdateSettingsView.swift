import SwiftUI

/// Update preferences and manual update checking.
struct UpdateSettingsView: View {

    @Bindable var updater: AppUpdater

    var body: some View {
        Form {
            Toggle("Automatically check for updates", isOn: $updater.automaticallyChecksForUpdates)
            Toggle("Automatically download and install updates", isOn: $updater.automaticallyDownloadsUpdates)
            Text("Updates install when the app quits. Restarts wait for builds, exports, and tool installation to finish.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Check for Updates…", action: updater.checkForUpdates)
                .disabled(!updater.canCheckForUpdates)
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }

}
