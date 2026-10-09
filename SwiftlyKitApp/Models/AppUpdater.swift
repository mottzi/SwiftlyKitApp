import AppKit
import Observation
import Sparkle

@Observable
/// App updates and user preferences managed by Sparkle.
final class AppUpdater: NSObject, SPUUpdaterDelegate {

    private(set) var canCheckForUpdates = false
    private var automaticChecksEnabled = true
    private var automaticDownloadsEnabled = false

    @ObservationIgnored private var controller: SPUStandardUpdaterController!
    @ObservationIgnored private var observations: [NSKeyValueObservation] = []
    private let activity: AppActivity

    init(activity: AppActivity) {
        self.activity = activity
        super.init()
        controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
        observePreferences()
    }

    /// Starts update checking after the application launches.
    func start() {
        controller.startUpdater()
    }

    /// Shows the standard update dialog for a user-initiated check.
    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }

    /// Whether Sparkle checks for new versions in the background.
    var automaticallyChecksForUpdates: Bool {
        get { automaticChecksEnabled }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }

    /// Whether Sparkle downloads updates for installation on quit.
    var automaticallyDownloadsUpdates: Bool {
        get { automaticDownloadsEnabled }
        set { controller.updater.automaticallyDownloadsUpdates = newValue }
    }

    /// Delays an update restart until work in every window finishes.
    func updater(
        _ updater: SPUUpdater,
        shouldPostponeRelaunchForUpdate item: SUAppcastItem,
        untilInvokingBlock installHandler: @escaping () -> Void
    ) -> Bool {
        guard activity.isBusy else { return false }
        activity.whenIdle(installHandler)
        return true
    }

}

extension AppUpdater {

    private func observePreferences() {

        observations = [
            controller.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
                MainActor.assumeIsolated { self?.canCheckForUpdates = updater.canCheckForUpdates }
            },
            controller.updater.observe(\.automaticallyChecksForUpdates, options: [.initial, .new]) {
                [weak self] updater, _ in
                MainActor.assumeIsolated { self?.automaticChecksEnabled = updater.automaticallyChecksForUpdates }
            },
            controller.updater.observe(\.automaticallyDownloadsUpdates, options: [.initial, .new]) {
                [weak self] updater, _ in
                MainActor.assumeIsolated { self?.automaticDownloadsEnabled = updater.automaticallyDownloadsUpdates }
            }
        ]
    }

}
