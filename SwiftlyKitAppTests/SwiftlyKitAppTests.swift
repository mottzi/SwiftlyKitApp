import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

@Suite(.serialized)
struct SwiftlyKitAppTests {

    @MainActor
    @Test
    func pagerUsesProductionRevealGeometryAtBothRestingPages() async {
        let firstPageFrames = await pagerFrames(progress: 0)
        expectHorizontalFrame(firstPageFrames[0], minX: 12, width: 178)
        expectHorizontalFrame(firstPageFrames[1], minX: 200, width: 216)

        let secondPageFrames = await pagerFrames(progress: 1)
        expectHorizontalFrame(secondPageFrames[0], minX: -176, width: 178)
        expectHorizontalFrame(secondPageFrames[1], minX: 12, width: 216)
    }

    @MainActor
    @Test
    func windowMinimumIncludesContentObscuredByTheUnifiedToolbar() async {
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
    func windowMinimumTracksResponsiveLayoutWithoutLosingWidthFloor() async {
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
    func windowMinimumDoesNotResizeTheWindowReentrantly() async {
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
            .compactMap({ $0 as? WindowMinimumSizeView })
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
    @Test
    func productDiscoverySpinnerDoesNotHostAnAppKitProgressIndicator() async {
        let hostingView = NSHostingView(rootView: AnyView(ProductDiscoverySpinner()))
        hostingView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)

        hostingView.layoutSubtreeIfNeeded()
        await Task.yield()
        hostingView.layoutSubtreeIfNeeded()

        let appKitProgressViews = descendantViews(of: hostingView).filter { view in
            view is NSProgressIndicator
                || String(reflecting: type(of: view)).contains("AppKitProgressView")
        }

        #expect(
            appKitProgressViews.isEmpty,
            "Product discovery must not add an AppKit progress indicator under the animated page scale."
        )

        hostingView.rootView = AnyView(EmptyView())
        await Task.yield()
    }

    @MainActor
    private func pagerFrames(progress: CGFloat) async -> [Int: CGRect] {
        let capture = PageFrameCapture()
        var layout = PagingHStack(
            spacing: 10,
            pageTrailingInset: 38,
            selection: 0
        )
        layout.progress = progress

        let rootView = layout {
            PageFrameProbe(index: 0, color: .red, capture: capture)
            PageFrameProbe(index: 1, color: .blue, capture: capture)
        }
        .padding(.horizontal, 12)
        .clipped()
        .frame(width: 240, height: 80)
        .coordinateSpace(.named("pagerViewport"))

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = CGRect(x: 0, y: 0, width: 240, height: 80)

        for _ in 0..<10 where capture.frames.count < 2 {
            hostingView.layoutSubtreeIfNeeded()
            await Task.yield()
        }

        return capture.frames
    }

    private func expectHorizontalFrame(_ frame: CGRect?, minX: CGFloat, width: CGFloat) {
        #expect(frame != nil)
        guard let frame else { return }

        #expect(abs(frame.minX - minX) < 0.5)
        #expect(abs(frame.width - width) < 0.5)
    }

    @MainActor
    private func descendantViews(of view: NSView) -> [NSView] {
        view.subviews.flatMap { subview in
            [subview] + descendantViews(of: subview)
        }
    }

    @MainActor
    private func settledMinimumSize(
        of window: NSWindow,
        contentWidth: CGFloat
    ) async -> CGSize {
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

@MainActor
private final class PageFrameCapture {

    var frames: [Int: CGRect] = [:]

}

private struct PageFrameProbe: View {

    let index: Int
    let color: Color
    let capture: PageFrameCapture

    var body: some View {
        color
            .onGeometryChange(for: CGRect.self) { geometry in
                geometry.frame(in: .named("pagerViewport"))
            } action: { frame in
                capture.frames[index] = frame
            }
    }

}

private struct ResponsiveMinimumContent: View {

    var body: some View {
        WidthResponsiveLayout {
            Color.clear
        }
        .frame(minWidth: 334)
    }

}

private struct WidthResponsiveLayout: Layout {

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = max(proposal.width ?? 334, 334)
        let height: CGFloat = width >= 500 ? 178 : 250
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        for subview in subviews {
            subview.place(
                at: bounds.origin,
                anchor: .topLeading,
                proposal: ProposedViewSize(
                    width: bounds.width,
                    height: bounds.height
                )
            )
        }
    }

}

@MainActor
private final class ContentSizeRecursionRecordingWindow: NSWindow {

    var didResizeReentrantly = false

    var isBridgeLayoutActive = false

    override func setContentSize(_ size: NSSize) {
        if isBridgeLayoutActive {
            didResizeReentrantly = true
        }

        super.setContentSize(size)
    }

}

private struct WindowMinimumSizeTestBridge: NSViewRepresentable {

    let visibleMinHeight: CGFloat

    func makeNSView(context: Context) -> WindowMinimumSizeView {
        WindowMinimumSizeView()
    }

    func updateNSView(_ nsView: WindowMinimumSizeView, context: Context) {
        nsView.visibleMinHeight = visibleMinHeight
    }

}
