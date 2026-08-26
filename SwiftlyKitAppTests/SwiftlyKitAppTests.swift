import Foundation
import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

struct SwiftlyKitAppTests {

    @MainActor
    @Test
    func pagerTransitionReachesTheOuterViewportEdgeForAnyInset() {
        let size = CGSize(width: 240, height: 80)

        for inset in [CGFloat(8), 16, 24] {
            let enteringPageAtRestImage = render(
                pager(inset: inset, progress: 0, size: size),
                size: size
            )
            let enteringPageAtRest = trailingEdgeColor(in: enteringPageAtRestImage)
            #expect(enteringPageAtRest?.alphaComponent ?? 0 < 0.1)

            let enteringPageInMotionImage = render(
                pager(inset: inset, progress: 0.01, size: size),
                size: size
            )
            let enteringPageInMotion = trailingEdgeColor(in: enteringPageInMotionImage)
            #expect(enteringPageInMotion?.blueComponent ?? 0 > enteringPageInMotion?.redComponent ?? 1)

            let leavingPageInMotionImage = render(
                pager(inset: inset, progress: 0.99, size: size),
                size: size
            )
            let leavingPageInMotion = leadingEdgeColor(in: leavingPageInMotionImage)
            #expect(leavingPageInMotion?.redComponent ?? 0 > leavingPageInMotion?.blueComponent ?? 1)

            let leavingPageAtRestImage = render(
                pager(inset: inset, progress: 1, size: size),
                size: size
            )
            let leavingPageAtRest = leadingEdgeColor(in: leavingPageAtRestImage)
            #expect(leavingPageAtRest?.alphaComponent ?? 0 < 0.1)
        }
    }

    @MainActor
    private func pager(inset: CGFloat, progress: CGFloat, size: CGSize) -> some View {
        PagingHStack(spacing: inset, progress: progress) {
            Rectangle().fill(.red)
            Rectangle().fill(.blue)
        }
        .padding(.horizontal, inset)
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
