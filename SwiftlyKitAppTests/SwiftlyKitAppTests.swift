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
                    .windowMinimumHeight()
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
        let absoluteMinimum = await settledMinimumSize(of: window, contentWidth: 1)

        #expect(abs(wideMinimum.height - 321) < 0.5)
        #expect(abs(narrowMinimum.height - 393) < 0.5)
        #expect(abs(restoredMinimum.height - wideMinimum.height) < 0.5)
        #expect(abs(absoluteMinimum.width - 334) < 0.5)

        await close(window, hostingView: hostingView)
    }

    @MainActor
    private func pagerFrames(progress: CGFloat) async -> [Int: CGRect] {
        let capture = PageFrameCapture()
        var layout = PagingHStack(
            spacing: Constants.pageSpacing,
            pageTrailingInset: Constants.pageTrailingInset,
            selection: 0
        )
        layout.progress = progress

        let rootView = layout {
            PageFrameProbe(index: 0, color: .red, capture: capture)
            PageFrameProbe(index: 1, color: .blue, capture: capture)
        }
        .padding(.horizontal, Constants.appHorizontalPadding)
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
        let hostingView = NSHostingView(rootView: AnyView(AppView()))
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
