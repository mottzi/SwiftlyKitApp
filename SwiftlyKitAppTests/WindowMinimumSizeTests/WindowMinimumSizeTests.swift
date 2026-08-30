import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

@Suite(.serialized)
struct WindowMinimumSizeTests {

    @MainActor
    @Test
    func fitsOnlyWindowsWithoutRestoredFrames() throws {
        let suiteName = "InitialWindowSizingTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        InitialWindowSizing.captureRestoredFrames(in: defaults)
        defaults.set("new-frame", forKey: "NSWindow Frame new-window")
        #expect(InitialWindowSizing.shouldFitWindow(named: "new-window"))

        defaults.set("saved-frame", forKey: "NSWindow Frame restored-window")
        InitialWindowSizing.captureRestoredFrames(in: defaults)
        #expect(!InitialWindowSizing.shouldFitWindow(named: "restored-window"))
    }

    @MainActor
    @Test
    func includesContentObscuredByTheUnifiedToolbar() async {
        let minimumContentHeight = CGFloat(281)
        let hostingView = NSHostingView(
            rootView: AnyView(
                Color.clear
                    .frame(width: 500, height: minimumContentHeight)
                    .windowMinimumSize()
            )
        )
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 500, height: minimumContentHeight),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.toolbar = NSToolbar(identifier: "WindowMinimumSizeBridgeTests")
        window.toolbarStyle = .unifiedCompact
        window.contentView = hostingView

        let obscuredContentHeight = window.frame.height - window.contentLayoutRect.height
        let expectedMinimumHeight = minimumContentHeight + obscuredContentHeight

        // wait for SwiftUI and AppKit to publish the bridged minimum before asserting
        for _ in 0..<10 where window.contentMinSize.height < expectedMinimumHeight {
            await Task.yield()
            hostingView.layoutSubtreeIfNeeded()
        }

        #expect(obscuredContentHeight > 0)
        #expect(abs(window.contentMinSize.height - expectedMinimumHeight) < 0.5)

        await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func tracksResponsiveLayoutWithoutLosingWidthFloor() async {
        let (window, hostingView) = responsiveLayoutWindow()

        let wideMinimum = await settledMinimumSize(of: window, contentWidth: 700)
        let narrowMinimum = await settledMinimumSize(of: window, contentWidth: 360)
        let restoredMinimum = await settledMinimumSize(of: window, contentWidth: 700)
        let minimumWidth = await settledMinimumSize(of: window, contentWidth: 334).width

        #expect(
            abs(wideMinimum.height - 322) < 0.5,
            "Measured wide minimum: \(wideMinimum)"
        )
        #expect(
            abs(narrowMinimum.height - 394) < 0.5,
            "Measured narrow minimum: \(narrowMinimum)"
        )
        #expect(abs(restoredMinimum.height - wideMinimum.height) < 0.5)
        #expect(abs(minimumWidth - 334) < 0.5)

        await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func doesNotResizeTheWindowReentrantly() async {
        let hostingView = NSHostingView(
            rootView: AnyView(
                Color.clear
                    .frame(width: 500, height: 281)
                    .background {
                        WindowMinimumSizeTestBridge(visibleMinHeight: 281)
                    }
            )
        )
        let window = ContentSizeRecursionRecordingWindow(
            contentRect: CGRect(x: 0, y: 0, width: 500, height: 100),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.toolbar = NSToolbar(identifier: "WindowMinimumRecursionTests")
        window.toolbarStyle = .unifiedCompact
        window.contentView = hostingView
        hostingView.layoutSubtreeIfNeeded()
        await Task.yield()
        hostingView.layoutSubtreeIfNeeded()

        guard let bridgeView = descendantViews(of: hostingView)
            .compactMap({ $0 as? WindowMinimumSizeAppKitView })
            .first else {
            #expect(Bool(false), "The window minimum bridge was not installed")
            await close(window, hostingView: hostingView)
            return
        }

        window.isBridgeLayoutActive = true
        bridgeView.layout()
        window.isBridgeLayoutActive = false

        #expect(!window.didResizeReentrantly)

        await close(window, hostingView: hostingView)
    }

    @MainActor
    private func settledMinimumSize(of window: NSWindow, contentWidth: CGFloat) async -> CGSize {
        var currentWidth = window.contentView?.bounds.width ?? contentWidth

        while abs(currentWidth - contentWidth) > 0.5 {
            let widthChange = min(max(contentWidth - currentWidth, -20), 20)
            currentWidth += widthChange
            window.setContentSize(CGSize(width: currentWidth, height: 700))
            try? await Task.sleep(for: .milliseconds(5))
            window.contentView?.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
        }

        window.setContentSize(CGSize(width: contentWidth, height: 1))

        var previousSize = CGSize.zero
        var stableReadingCount = 0

        for _ in 0..<100 {
            try? await Task.sleep(for: .milliseconds(10))
            window.contentView?.layoutSubtreeIfNeeded()
            window.displayIfNeeded()

            let currentSize = window.contentView?.bounds.size ?? .zero
            let unchanged = abs(currentSize.width - previousSize.width) < 0.5
                && abs(currentSize.height - previousSize.height) < 0.5

            if currentSize.height > 1, unchanged {
                stableReadingCount += 1
                if stableReadingCount == 3 { return currentSize }
            } else {
                stableReadingCount = 0
            }

            previousSize = currentSize
        }

        return window.contentView?.bounds.size ?? .zero
    }

    @MainActor
    private func responsiveLayoutWindow() -> (NSWindow, NSHostingView<AnyView>) {
        let hostingView = NSHostingView(
            rootView: AnyView(
                ResponsiveMinimumContent()
                    .windowMinimumSize(addingHeight: 104)
            )
        )
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 700, height: 700),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.toolbar = NSToolbar(identifier: "ResponsiveWindowMinimumTests")
        window.toolbarStyle = .unifiedCompact
        window.contentView = hostingView
        window.orderFront(nil)

        return (window, hostingView)
    }

    @MainActor
    private func close(_ window: NSWindow, hostingView: NSHostingView<AnyView>) async {
        window.orderOut(nil)
        hostingView.rootView = AnyView(EmptyView())

        for _ in 0..<3 {
            await Task.yield()
            hostingView.layoutSubtreeIfNeeded()
        }

        window.contentView = nil
        window.close()
    }

}
