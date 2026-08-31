import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

@Suite(.serialized)
struct WindowMinimumSizeTests {

    @MainActor
    @Test
    func includesContentObscuredByTheUnifiedToolbar() async throws {
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

        try await settleBridge(
            in: hostingView,
            window: window,
            expectedMinimumHeight: expectedMinimumHeight
        )

        #expect(obscuredContentHeight > 0)
        #expect(abs(window.contentMinSize.height - expectedMinimumHeight) < 0.5)

        try await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func reservesResponsiveHeightBeforeTheFirstNarrowLayout() async throws {
        let (window, hostingView) = responsiveLayoutWindow(contentWidth: 700)

        let wideMinimum = try await settledMinimumSize(of: window, contentWidth: 700)
        let expectedHeight = expectedMinimumHeight(
            in: window,
            reservedContentHeight: ResponsiveMinimumContent.reservedHeight,
            additionalContentHeight: 104
        )

        #expect(
            abs(wideMinimum.height - expectedHeight) < 0.5,
            "Measured wide minimum: \(wideMinimum)"
        )

        let minimumWidth = try await settledMinimumSize(of: window, contentWidth: 334).width
        #expect(abs(minimumWidth - 334) < 0.5)

        try await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func preservesHeightDuringWideNarrowWideResize() async throws {
        try await expectStableHeight(through: [700, 360, 700])
    }

    @MainActor
    @Test
    func preservesHeightDuringNarrowWideNarrowResize() async throws {
        try await expectStableHeight(through: [360, 700, 360])
    }

    @MainActor
    @Test
    func appViewPreservesHeightThroughBothColumnTransitions() async throws {
        let hostingView = NSHostingView(rootView: AnyView(AppView()))
        let window = minimumSizeWindow(
            contentWidth: 700,
            contentHeight: 700,
            hostingView: hostingView,
            toolbarIdentifier: "AppViewHorizontalResizeTests"
        )
        window.orderFront(nil)

        let initialSize = try await settledMinimumSize(
            of: window,
            contentWidth: 700
        )
        let initialFrameHeight = window.frame.height

        for contentWidth in [300, 700, 300] as [CGFloat] {
            let size = try await settledSizeAfterHorizontalResize(
                of: window,
                contentWidth: contentWidth,
                preservingContentHeight: initialSize.height,
                preservingFrameHeight: initialFrameHeight
            )

            #expect(abs(size.height - initialSize.height) < 0.5)
            #expect(abs(window.frame.height - initialFrameHeight) < 0.5)
        }

        try await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func reservationIsAFloorRatherThanAHeightCap() async throws {
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
        let minimum = try await settledMinimumSize(of: window, contentWidth: 500)
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

        try await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func widthFloorCorrectionPreservesAUserHeightAboveTheFloor() async throws {
        let (window, hostingView) = responsiveLayoutWindow(contentWidth: 700)
        let minimum = try await settledMinimumSize(of: window, contentWidth: 700)
        let userContentHeight = minimum.height + 80
        window.setContentSize(
            CGSize(width: 700, height: userContentHeight)
        )
        let settledUserSize = try await settledWindowSize(of: window)
        let userFrameHeight = window.frame.height

        let correctedSize = try await settledSizeAfterHorizontalResize(
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

        try await close(window, hostingView: hostingView)
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

        let wideMinimum = try await settledMinimumSize(
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

        try await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func doesNotResizeTheWindowReentrantly() async throws {
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
            try await close(window, hostingView: hostingView)
            return
        }

        window.isBridgeLayoutActive = true
        bridgeView.layout()
        window.isBridgeLayoutActive = false

        #expect(!window.didResizeReentrantly)

        try await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func keepsIndependentMinimumsForTwoWindows() async throws {
        let firstHeight = CGFloat(220)
        let secondHeight = CGFloat(310)
        let firstHostingView = bridgeHostingView(visibleMinHeight: firstHeight)
        let secondHostingView = bridgeHostingView(visibleMinHeight: secondHeight)
        let firstWindow = minimumSizeWindow(
            contentWidth: 500,
            contentHeight: 500,
            hostingView: firstHostingView,
            toolbarIdentifier: "FirstIndependentWindowMinimumTests"
        )
        let secondWindow = minimumSizeWindow(
            contentWidth: 500,
            contentHeight: 500,
            hostingView: secondHostingView,
            toolbarIdentifier: "SecondIndependentWindowMinimumTests"
        )
        firstWindow.orderFront(nil)
        secondWindow.orderFront(nil)

        try await settleBridge(
            in: firstHostingView,
            window: firstWindow,
            expectedMinimumHeight: expectedMinimumHeight(
                in: firstWindow,
                reservedContentHeight: firstHeight,
                additionalContentHeight: 0
            )
        )
        try await settleBridge(
            in: secondHostingView,
            window: secondWindow,
            expectedMinimumHeight: expectedMinimumHeight(
                in: secondWindow,
                reservedContentHeight: secondHeight,
                additionalContentHeight: 0
            )
        )

        #expect(
            abs(
                firstWindow.contentMinSize.height
                    - expectedMinimumHeight(
                        in: firstWindow,
                        reservedContentHeight: firstHeight,
                        additionalContentHeight: 0
                    )
            ) < 0.5
        )
        #expect(
            abs(
                secondWindow.contentMinSize.height
                    - expectedMinimumHeight(
                        in: secondWindow,
                        reservedContentHeight: secondHeight,
                        additionalContentHeight: 0
                    )
            ) < 0.5
        )

        try await close(firstWindow, hostingView: firstHostingView)
        try await close(secondWindow, hostingView: secondHostingView)
    }

    @MainActor
    @Test
    func restoresHostingSizingOptionsAfterDetachment() async throws {
        let hostingView = bridgeHostingView(visibleMinHeight: 240)
        let originalOptions: NSHostingSizingOptions = [.minSize, .maxSize]
        hostingView.sizingOptions = originalOptions
        let window = minimumSizeWindow(
            contentWidth: 500,
            contentHeight: 500,
            hostingView: hostingView,
            toolbarIdentifier: "WindowMinimumDetachTests"
        )

        try await settleBridge(
            in: hostingView,
            window: window,
            expectedMinimumHeight: expectedMinimumHeight(
                in: window,
                reservedContentHeight: 240,
                additionalContentHeight: 0
            )
        )
        try await waitForManagedHostingOptions(hostingView, window: window)
        #expect(!hostingView.sizingOptions.contains(.minSize))
        #expect(hostingView.sizingOptions.contains(.intrinsicContentSize))

        hostingView.rootView = AnyView(EmptyView())
        try await waitForBridgeRemoval(
            from: hostingView,
            window: window,
            expectedSizingOptions: originalOptions
        )

        #expect(hostingView.sizingOptions == originalOptions)
        try await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func restoresAndManagesHostingOptionsAcrossReattachment() async throws {
        let hostingView = bridgeHostingView(visibleMinHeight: 240)
        let originalOptions: NSHostingSizingOptions = [.minSize, .maxSize]
        hostingView.sizingOptions = originalOptions
        let window = minimumSizeWindow(
            contentWidth: 500,
            contentHeight: 500,
            hostingView: hostingView,
            toolbarIdentifier: "WindowMinimumReattachTests"
        )

        try await settleBridge(
            in: hostingView,
            window: window,
            expectedMinimumHeight: expectedMinimumHeight(
                in: window,
                reservedContentHeight: 240,
                additionalContentHeight: 0
            )
        )
        try await waitForManagedHostingOptions(hostingView, window: window)

        hostingView.rootView = AnyView(EmptyView())
        try await waitForBridgeRemoval(
            from: hostingView,
            window: window,
            expectedSizingOptions: originalOptions
        )
        #expect(hostingView.sizingOptions == originalOptions)

        hostingView.rootView = bridgeRootView(visibleMinHeight: 240)
        try await settleBridge(
            in: hostingView,
            window: window,
            expectedMinimumHeight: expectedMinimumHeight(
                in: window,
                reservedContentHeight: 240,
                additionalContentHeight: 0
            )
        )
        try await waitForManagedHostingOptions(hostingView, window: window)
        #expect(!hostingView.sizingOptions.contains(.minSize))
        #expect(hostingView.sizingOptions.contains(.intrinsicContentSize))

        hostingView.rootView = AnyView(EmptyView())
        try await waitForBridgeRemoval(
            from: hostingView,
            window: window,
            expectedSizingOptions: originalOptions
        )
        #expect(hostingView.sizingOptions == originalOptions)

        try await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func cancelsPendingMinimumUpdateWhenDetached() async throws {
        let hostingView = bridgeHostingView(visibleMinHeight: 220)
        let originalOptions = hostingView.sizingOptions
        let window = minimumSizeWindow(
            contentWidth: 500,
            contentHeight: 500,
            hostingView: hostingView,
            toolbarIdentifier: "WindowMinimumPendingDetachTests"
        )
        try await settleBridge(
            in: hostingView,
            window: window,
            expectedMinimumHeight: expectedMinimumHeight(
                in: window,
                reservedContentHeight: 220,
                additionalContentHeight: 0
            )
        )
        let originalMinimum = window.contentMinSize

        hostingView.rootView = bridgeRootView(visibleMinHeight: 400)
        hostingView.layoutSubtreeIfNeeded()
        hostingView.rootView = AnyView(EmptyView())
        try await waitForBridgeRemoval(
            from: hostingView,
            window: window,
            expectedSizingOptions: originalOptions
        )
        #expect(hostingView.sizingOptions == originalOptions)
        let detachedMinimum = window.contentMinSize

        for _ in 0..<3 { await Task.yield() }

        #expect(window.contentMinSize == detachedMinimum)
        #expect(window.contentMinSize.height <= originalMinimum.height)
        try await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func recalculatesMinimumAfterToolbarVisibilityChanges() async throws {
        let visibleHeight = CGFloat(281)
        let hostingView = bridgeHostingView(visibleMinHeight: visibleHeight)
        let window = minimumSizeWindow(
            contentWidth: 500,
            contentHeight: 500,
            hostingView: hostingView,
            toolbarIdentifier: "WindowMinimumToolbarChangeTests"
        )
        window.orderFront(nil)
        try await settleBridge(
            in: hostingView,
            window: window,
            expectedMinimumHeight: expectedMinimumHeight(
                in: window,
                reservedContentHeight: visibleHeight,
                additionalContentHeight: 0
            )
        )
        let visibleToolbarMinimum = window.contentMinSize.height

        window.toolbar?.isVisible = false
        window.displayIfNeeded()
        let expectedHeight = expectedMinimumHeight(
            in: window,
            reservedContentHeight: visibleHeight,
            additionalContentHeight: 0
        )
        try await settleBridge(
            in: hostingView,
            window: window,
            expectedMinimumHeight: expectedHeight
        )
        #expect(abs(window.contentMinSize.height - expectedHeight) < 0.5)
        #expect(window.contentMinSize.height <= visibleToolbarMinimum)

        try await close(window, hostingView: hostingView)
    }

    @MainActor
    private func settledMinimumSize(
        of window: NSWindow,
        contentWidth: CGFloat
    ) async throws -> CGSize {
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

        let error = TestWaitTimeout(
            "Window minimum did not settle. "
                + windowDiagnostics(window, expectedMinimumHeight: nil)
        )
        forceClose(window)
        throw error
    }

    @MainActor
    private func expectStableHeight(through contentWidths: [CGFloat]) async throws {
        guard let initialWidth = contentWidths.first else { return }

        let (window, hostingView) = responsiveLayoutWindow(
            contentWidth: initialWidth
        )
        let initialSize = try await settledMinimumSize(
            of: window,
            contentWidth: initialWidth
        )
        let initialFrameHeight = window.frame.height
        var measuredSizes = [initialSize]

        for contentWidth in contentWidths.dropFirst() {
            let size = try await settledSizeAfterHorizontalResize(
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

        try await close(window, hostingView: hostingView)
    }

    @MainActor
    private func settledSizeAfterHorizontalResize(
        of window: NSWindow,
        contentWidth: CGFloat,
        preservingContentHeight contentHeight: CGFloat,
        preservingFrameHeight frameHeight: CGFloat
    ) async throws -> CGSize {
        var currentWidth = window.contentView?.bounds.width ?? contentWidth

        while abs(currentWidth - contentWidth) > 0.5 {
            let widthChange = min(max(contentWidth - currentWidth, -20), 20)
            currentWidth += widthChange
            window.setContentSize(
                CGSize(width: currentWidth, height: contentHeight)
            )
            let measuredSize = try await settledWindowSize(of: window)
            #expect(
                abs(measuredSize.height - contentHeight) < 0.5,
                "Width: \(currentWidth), content size: \(measuredSize)"
            )
            #expect(
                abs(window.frame.height - frameHeight) < 0.5,
                "Width: \(currentWidth), frame: \(window.frame)"
            )
        }

        return try await settledWindowSize(of: window)
    }

    @MainActor
    private func settledWindowSize(of window: NSWindow) async throws -> CGSize {
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

        let error = TestWaitTimeout(
            "Window size did not settle. "
                + windowDiagnostics(window, expectedMinimumHeight: nil)
        )
        forceClose(window)
        throw error
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
    private func bridgeHostingView(
        visibleMinHeight: CGFloat
    ) -> NSHostingView<AnyView> {
        NSHostingView(rootView: bridgeRootView(visibleMinHeight: visibleMinHeight))
    }

    @MainActor
    private func bridgeRootView(
        visibleMinHeight: CGFloat
    ) -> AnyView {
        AnyView(
            Color.clear
                .frame(width: 500, height: visibleMinHeight)
                .background {
                    WindowMinimumSizeTestBridge(
                        visibleMinHeight: visibleMinHeight
                    )
                }
        )
    }

    @MainActor
    private func settleBridge(
        in hostingView: NSHostingView<AnyView>,
        window: NSWindow,
        expectedMinimumHeight: CGFloat
    ) async throws {
        for _ in 0..<100 {
            hostingView.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
            await Task.yield()

            if abs(window.contentMinSize.height - expectedMinimumHeight) < 0.5 {
                return
            }

            try? await Task.sleep(for: .milliseconds(5))
        }

        let error = TestWaitTimeout(
            "Bridge minimum did not settle. "
                + windowDiagnostics(
                    window,
                    hostingView: hostingView,
                    expectedMinimumHeight: expectedMinimumHeight,
                    expectedSizingOptions: "without .minSize and with .intrinsicContentSize"
                )
        )
        forceClose(window, hostingView: hostingView)
        throw error
    }

    @MainActor
    private func waitForManagedHostingOptions(
        _ hostingView: NSHostingView<AnyView>,
        window: NSWindow
    ) async throws {
        for _ in 0..<100 {
            hostingView.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
            await Task.yield()

            if !hostingView.sizingOptions.contains(.minSize)
                    && hostingView.sizingOptions.contains(.intrinsicContentSize) {
                return
            }

            try? await Task.sleep(for: .milliseconds(5))
        }

        let error = TestWaitTimeout(
            "Hosting sizing options were not managed. "
                + windowDiagnostics(
                    window,
                    hostingView: hostingView,
                    expectedMinimumHeight: nil,
                    expectedSizingOptions: "without .minSize and with .intrinsicContentSize"
                )
        )
        forceClose(window, hostingView: hostingView)
        throw error
    }

    @MainActor
    private func waitForBridgeRemoval(
        from hostingView: NSHostingView<AnyView>,
        window: NSWindow,
        expectedSizingOptions: NSHostingSizingOptions
    ) async throws {
        for _ in 0..<100 {
            hostingView.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
            await Task.yield()

            if windowMinimumBridge(in: hostingView) == nil {
                return
            }

            try? await Task.sleep(for: .milliseconds(5))
        }

        let error = TestWaitTimeout(
            "SwiftUI did not remove the window minimum bridge. "
                + windowDiagnostics(
                    window,
                    hostingView: hostingView,
                    expectedMinimumHeight: nil,
                    expectedSizingOptions: String(describing: expectedSizingOptions)
                )
        )
        forceClose(window, hostingView: hostingView)
        throw error
    }

    @MainActor
    private func windowMinimumBridge(
        in hostingView: NSHostingView<AnyView>
    ) -> WindowMinimumSizeAppKitView? {
        descendantViews(of: hostingView)
            .compactMap { $0 as? WindowMinimumSizeAppKitView }
            .first
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
    private func close(
        _ window: NSWindow,
        hostingView: NSHostingView<AnyView>
    ) async throws {
        window.orderOut(nil)
        hostingView.rootView = AnyView(EmptyView())

        for _ in 0..<100 {
            await Task.yield()
            hostingView.layoutSubtreeIfNeeded()

            if windowMinimumBridge(in: hostingView) == nil {
                window.contentView = nil
                window.close()
                return
            }
        }

        let error = TestWaitTimeout(
            "Cleanup timed out waiting for bridge removal. "
                + windowDiagnostics(
                    window,
                    hostingView: hostingView,
                    expectedMinimumHeight: nil,
                    expectedSizingOptions: "restored original options"
                )
        )
        forceClose(window, hostingView: hostingView)
        throw error
    }

    @MainActor
    private func forceClose(
        _ window: NSWindow,
        hostingView: NSHostingView<AnyView>? = nil
    ) {
        let host = hostingView ?? window.contentView as? NSHostingView<AnyView>
        host?.rootView = AnyView(EmptyView())
        host?.layoutSubtreeIfNeeded()
        window.orderOut(nil)
        window.contentView = nil
        window.close()
    }

    @MainActor
    private func windowDiagnostics(
        _ window: NSWindow,
        hostingView: NSHostingView<AnyView>? = nil,
        expectedMinimumHeight: CGFloat?,
        expectedSizingOptions: String = "not specified"
    ) -> String {
        let host = hostingView ?? window.contentView as? NSHostingView<AnyView>
        let bridgeExists = host.map { windowMinimumBridge(in: $0) != nil } ?? false
        let expectedContentMinSize = expectedMinimumHeight.map {
            "height approximately \($0)"
        } ?? "not specified"

        return "Expected contentMinSize: \(expectedContentMinSize); "
            + "actual contentMinSize: \(window.contentMinSize); "
            + "expected sizingOptions: \(expectedSizingOptions); "
            + "actual sizingOptions: \(String(describing: host?.sizingOptions)); "
            + "bridge exists: \(bridgeExists); "
            + "window content size: \(String(describing: window.contentView?.bounds.size))."
    }

}

private struct TestWaitTimeout: Error, CustomStringConvertible {

    let description: String

    init(_ description: String) {
        self.description = description
    }

}
