import SwiftUI

@main
struct SwiftlyKitApp: App {

    init() {
        InitialWindowSizing.captureRestoredFrames()
    }

    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .defaultWindowPlacement { content, context in
            let availableSize = context.defaultDisplay.visibleRect.size
            let measuredSize = content.sizeThatFits(
                ProposedViewSize(width: Self.defaultWindowWidth, height: nil)
            )

            return WindowPlacement(
                size: CGSize(
                    width: min(Self.defaultWindowWidth, availableSize.width),
                    height: min(measuredSize.height, availableSize.height)
                )
            )
        }
        .windowToolbarStyle(.automatic)
        .windowResizability(.contentMinSize)
    }

}

extension SwiftlyKitApp {

    static let defaultWindowWidth: CGFloat = 500

}

/// Snapshots restorable frames before SwiftUI creates windows so the bridge can identify new ones.
enum InitialWindowSizing {

    private static let frameKeyPrefix = "NSWindow Frame "

    private static var restoredFrameKeys: Set<String> = []

    static func captureRestoredFrames(in defaults: UserDefaults = .standard) {
        restoredFrameKeys = Set(
            defaults.dictionaryRepresentation().keys.filter {
                $0.hasPrefix(frameKeyPrefix)
            }
        )
    }

    static func shouldFitWindow(named autosaveName: String) -> Bool {
        return !restoredFrameKeys.contains(frameKeyPrefix + autosaveName)
    }

}
