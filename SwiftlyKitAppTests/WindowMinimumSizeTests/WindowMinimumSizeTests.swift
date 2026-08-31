import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

@Suite(.serialized)
struct WindowMinimumSizeTests {

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
    func reservesResponsiveHeightBeforeTheFirstNarrowLayout() async {
        let (window, hostingView) = responsiveLayoutWindow(contentWidth: 700)

        let wideMinimum = await settledMinimumSize(of: window, contentWidth: 700)
        let expectedHeight = expectedMinimumHeight(
            in: window,
            reservedContentHeight: ResponsiveMinimumContent.reservedHeight,
            additionalContentHeight: 104
        )

        #expect(
            abs(wideMinimum.height - expectedHeight) < 0.5,
            "Measured wide minimum: \(wideMinimum)"
        )

        let minimumWidth = await settledMinimumSize(of: window, contentWidth: 334).width
        #expect(abs(minimumWidth - 334) < 0.5)

        await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func preservesHeightDuringWideNarrowWideResize() async {
        await expectStableHeight(through: [700, 360, 700])
    }

    @MainActor
    @Test
    func preservesHeightDuringNarrowWideNarrowResize() async {
        await expectStableHeight(through: [360, 700, 360])
    }

    @MainActor
    @Test
    func appViewPreservesHeightThroughBothColumnTransitions() async {
        let hostingView = NSHostingView(rootView: AnyView(AppView()))
        let window = minimumSizeWindow(
            contentWidth: 700,
            contentHeight: 700,
            hostingView: hostingView,
            toolbarIdentifier: "AppViewHorizontalResizeTests"
        )
        window.orderFront(nil)

        let initialSize = await settledMinimumSize(
            of: window,
            contentWidth: 700
        )
        let initialFrameHeight = window.frame.height

        for contentWidth in [300, 700, 300] as [CGFloat] {
            let size = await settledSizeAfterHorizontalResize(
                of: window,
                contentWidth: contentWidth,
                preservingContentHeight: initialSize.height,
                preservingFrameHeight: initialFrameHeight
            )

            #expect(abs(size.height - initialSize.height) < 0.5)
            #expect(abs(window.frame.height - initialFrameHeight) < 0.5)
        }

        await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func reservationIsAFloorRatherThanAHeightCap() async {
        let contentHeight = CGFloat(281)
        let reservation = CGFloat(250)
        let hostingView = NSHostingView(
            rootView: AnyView(
                Color.clear
                    .frame(width: 500, height: contentHeight)
                    .windowMinimumHeightReservation(reservation)
                    .windowMinimumSize()
            )
        )
        let window = minimumSizeWindow(
            contentWidth: 500,
            contentHeight: contentHeight,
            hostingView: hostingView,
            toolbarIdentifier: "WindowMinimumFloorTests"
        )
        let minimum = await settledMinimumSize(of: window, contentWidth: 500)
        let expectedHeight = expectedMinimumHeight(
            in: window,
            reservedContentHeight: contentHeight,
            additionalContentHeight: 0
        )

        #expect(contentHeight > reservation)
        #expect(
            abs(minimum.height - expectedHeight) < 0.5,
            "Measured minimum: \(minimum)"
        )

        await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func widthFloorCorrectionPreservesAUserHeightAboveTheFloor() async {
        let (window, hostingView) = responsiveLayoutWindow(contentWidth: 700)
        let minimum = await settledMinimumSize(of: window, contentWidth: 700)
        let userContentHeight = minimum.height + 80
        window.setContentSize(
            CGSize(width: 700, height: userContentHeight)
        )
        let settledUserSize = await settledWindowSize(of: window)
        let userFrameHeight = window.frame.height

        let correctedSize = await settledSizeAfterHorizontalResize(
            of: window,
            contentWidth: 300,
            preservingContentHeight: settledUserSize.height,
            preservingFrameHeight: userFrameHeight
        )

        #expect(
            abs(correctedSize.width - 334) < 0.5,
            "Width-floor correction produced: \(correctedSize)"
        )
        #expect(
            abs(correctedSize.height - settledUserSize.height) < 0.5,
            "Wide size: \(settledUserSize), corrected size: \(correctedSize)"
        )
        #expect(abs(window.frame.height - userFrameHeight) < 0.5)

        await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func packageReservationMatchesNarrowContentBeforeNarrowLayout() async throws {
        let wideWidth = CGFloat(620)
        // AppView's 300-point floor minus its two 12-point horizontal paddings.
        let minimumPageWidth = CGFloat(276)
        let narrowContentHeight = try await reportedPackageConfigurationHeight(
            for: CGSize(width: minimumPageWidth, height: 300)
        )
        let hostingView = NSHostingView(
            rootView: AnyView(
                PackageConfigurationPage(onContentHeightChange: { _ in })
                    .preferredColorScheme(.dark)
                    .environment(PackageModel())
                    .environment(BuildOptions())
                    .frame(width: wideWidth)
                    .windowMinimumSize()
            )
        )
        let window = minimumSizeWindow(
            contentWidth: wideWidth,
            contentHeight: 700,
            hostingView: hostingView,
            toolbarIdentifier: "PackageConfigurationReservationTests"
        )
        window.orderFront(nil)

        let wideMinimum = await settledMinimumSize(
            of: window,
            contentWidth: wideWidth
        )
        let expectedHeight = expectedMinimumHeight(
            in: window,
            reservedContentHeight: narrowContentHeight,
            additionalContentHeight: 0
        )

        #expect(
            abs(wideMinimum.height - expectedHeight) < 0.5,
            "Narrow content: \(narrowContentHeight), wide minimum: \(wideMinimum)"
        )

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
    private func expectStableHeight(through contentWidths: [CGFloat]) async {
        guard let initialWidth = contentWidths.first else { return }

        let (window, hostingView) = responsiveLayoutWindow(
            contentWidth: initialWidth
        )
        let initialSize = await settledMinimumSize(
            of: window,
            contentWidth: initialWidth
        )
        let initialFrameHeight = window.frame.height
        var measuredSizes = [initialSize]

        for contentWidth in contentWidths.dropFirst() {
            let size = await settledSizeAfterHorizontalResize(
                of: window,
                contentWidth: contentWidth,
                preservingContentHeight: initialSize.height,
                preservingFrameHeight: initialFrameHeight
            )
            measuredSizes.append(size)

            #expect(
                abs(size.height - initialSize.height) < 0.5,
                "Widths: \(contentWidths), measured sizes: \(measuredSizes)"
            )
            #expect(abs(window.frame.height - initialFrameHeight) < 0.5)
        }

        await close(window, hostingView: hostingView)
    }

    @MainActor
    private func settledSizeAfterHorizontalResize(
        of window: NSWindow,
        contentWidth: CGFloat,
        preservingContentHeight contentHeight: CGFloat,
        preservingFrameHeight frameHeight: CGFloat
    ) async -> CGSize {
        var currentWidth = window.contentView?.bounds.width ?? contentWidth

        while abs(currentWidth - contentWidth) > 0.5 {
            let widthChange = min(max(contentWidth - currentWidth, -20), 20)
            currentWidth += widthChange
            window.setContentSize(
                CGSize(width: currentWidth, height: contentHeight)
            )
            let measuredSize = await settledWindowSize(of: window)
            #expect(
                abs(measuredSize.height - contentHeight) < 0.5,
                "Width: \(currentWidth), content size: \(measuredSize)"
            )
            #expect(
                abs(window.frame.height - frameHeight) < 0.5,
                "Width: \(currentWidth), frame: \(window.frame)"
            )
        }

        return await settledWindowSize(of: window)
    }

    @MainActor
    private func settledWindowSize(of window: NSWindow) async -> CGSize {
        var previousSize = CGSize.zero
        var stableReadingCount = 0

        for _ in 0..<100 {
            try? await Task.sleep(for: .milliseconds(10))
            window.contentView?.layoutSubtreeIfNeeded()
            window.displayIfNeeded()

            let currentSize = window.contentView?.bounds.size ?? .zero
            let unchanged = abs(currentSize.width - previousSize.width) < 0.5
                && abs(currentSize.height - previousSize.height) < 0.5

            if unchanged {
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
    private func responsiveLayoutWindow(
        contentWidth: CGFloat
    ) -> (NSWindow, NSHostingView<AnyView>) {
        let hostingView = NSHostingView(
            rootView: AnyView(
                ResponsiveMinimumContent()
                    .windowMinimumHeightReservation(
                        ResponsiveMinimumContent.reservedHeight
                    )
                    .windowMinimumSize(addingHeight: 104)
            )
        )
        let window = minimumSizeWindow(
            contentWidth: contentWidth,
            contentHeight: 700,
            hostingView: hostingView,
            toolbarIdentifier: "ResponsiveWindowMinimumTests"
        )
        window.orderFront(nil)

        return (window, hostingView)
    }

    @MainActor
    private func minimumSizeWindow(
        contentWidth: CGFloat,
        contentHeight: CGFloat,
        hostingView: NSHostingView<AnyView>,
        toolbarIdentifier: String
    ) -> NSWindow {
        let window = NSWindow(
            contentRect: CGRect(
                x: 0,
                y: 0,
                width: contentWidth,
                height: contentHeight
            ),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.toolbar = NSToolbar(identifier: toolbarIdentifier)
        window.toolbarStyle = .unifiedCompact
        window.contentView = hostingView

        return window
    }

    @MainActor
    private func expectedMinimumHeight(
        in window: NSWindow,
        reservedContentHeight: CGFloat,
        additionalContentHeight: CGFloat
    ) -> CGFloat {
        let obscuredContentHeight = max(
            window.frame.height - window.contentLayoutRect.height,
            0
        )
        return reservedContentHeight
            + obscuredContentHeight
            + additionalContentHeight
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
