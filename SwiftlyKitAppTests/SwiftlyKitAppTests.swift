import Foundation
import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

struct SwiftlyKitAppTests {

    @MainActor
    @Test
    func pagerTransitionReachesTheOuterViewportEdgeForAnyOuterPadding() {
        let size = CGSize(width: 240, height: 80)

        for outerPadding in [CGFloat(8), 16, 24] {
            let enteringPageAtRestImage = render(
                pager(
                    spacing: outerPadding,
                    outerPadding: outerPadding,
                    progress: 0,
                    size: size
                ),
                size: size
            )
            let enteringPageAtRest = trailingEdgeColor(in: enteringPageAtRestImage)
            #expect((enteringPageAtRest?.alphaComponent ?? 1) < 0.1)

            let enteringPageInMotionImage = render(
                pager(
                    spacing: outerPadding,
                    outerPadding: outerPadding,
                    progress: 0.01,
                    size: size
                ),
                size: size
            )
            let enteringPageInMotion = trailingEdgeColor(in: enteringPageInMotionImage)
            #expect(
                (enteringPageInMotion?.blueComponent ?? 0)
                    > (enteringPageInMotion?.redComponent ?? 1)
            )

            let leavingPageInMotionImage = render(
                pager(
                    spacing: outerPadding,
                    outerPadding: outerPadding,
                    progress: 0.99,
                    size: size
                ),
                size: size
            )
            let leavingPageInMotion = leadingEdgeColor(in: leavingPageInMotionImage)
            #expect(
                (leavingPageInMotion?.redComponent ?? 0)
                    > (leavingPageInMotion?.blueComponent ?? 1)
            )

            let leavingPageAtRestImage = render(
                pager(
                    spacing: outerPadding,
                    outerPadding: outerPadding,
                    progress: 1,
                    size: size
                ),
                size: size
            )
            let leavingPageAtRest = leadingEdgeColor(in: leavingPageAtRestImage)
            #expect((leavingPageAtRest?.alphaComponent ?? 1) < 0.1)
        }
    }

    @MainActor
    @Test
    func buildSectionKeepsAVisibleHeightBeforePackageSelection() {
        let capture = SizeCapture()
        let rootView = SizeProbeLayout(
            proposal: ProposedViewSize(width: 240, height: 0),
            capture: capture
        ) {
            BuildSection()
                .environment(PackageModel())
        }
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = CGRect(
            origin: .zero,
            size: CGSize(width: 240, height: 1)
        )
        hostingView.layoutSubtreeIfNeeded()

        #expect(capture.size.height > 0)
    }

    @MainActor
    @Test
    func windowMinimumIncludesContentObscuredByTheUnifiedToolbar() async {
        let minimumContentHeight = CGFloat(281)
        let hostingView = NSHostingView(
            rootView: WindowMinimumSizeBridge(minimumHeight: minimumContentHeight)
                .frame(width: 500, height: minimumContentHeight)
        )
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 500, height: minimumContentHeight),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.toolbar = NSToolbar(identifier: "WindowMinimumSizeBridgeTests")
        window.toolbarStyle = .unifiedCompact
        window.contentView = hostingView
        window.orderFront(nil)

        // The representable receives its NSWindow on the next main-actor turn.
        await Task.yield()
        await Task.yield()
        hostingView.layoutSubtreeIfNeeded()

        let obscuredContentHeight = window.frame.height - window.contentLayoutRect.height
        #expect(obscuredContentHeight > 0)
        #expect(window.minSize.height >= minimumContentHeight + obscuredContentHeight)
    }

    @MainActor
    private func pager(
        spacing: CGFloat,
        outerPadding: CGFloat,
        progress: CGFloat,
        size: CGSize
    ) -> some View {
        var layout = PagingHStack(spacing: spacing, pageTrailingInset: 0, selection: 0)
        layout.progress = progress

        return layout {
            Rectangle().fill(.red)
            Rectangle().fill(.blue)
        }
        .padding(.horizontal, outerPadding)
        .clipped()
        .frame(width: size.width, height: size.height)
    }

    private func trailingEdgeColor(in image: NSBitmapImageRep) -> NSColor? {
        image.colorAt(x: image.pixelsWide - 1, y: image.pixelsHigh / 2)
    }

    private func leadingEdgeColor(in image: NSBitmapImageRep) -> NSColor? {
        image.colorAt(x: 0, y: image.pixelsHigh / 2)
    }

    @MainActor
    private func render<Content: View>(_ content: Content, size: CGSize) -> NSBitmapImageRep {
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)!
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
        return bitmap
    }
}

private final class SizeCapture: @unchecked Sendable {

    var size = CGSize.zero

}

private struct SizeProbeLayout: Layout {

    let proposal: ProposedViewSize
    let capture: SizeCapture

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let size = subviews.first?.sizeThatFits(self.proposal) ?? .zero
        capture.size = size
        return size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: self.proposal)
    }

}
