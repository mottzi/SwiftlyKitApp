import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

@Suite(.serialized)
struct PagingHStackTests {

    @MainActor
    @Test
    func usesProductionRevealGeometryAtBothRestingPages() async {
        let firstPageFrames = await pagerFrames(progress: 0)
        expectHorizontalFrame(firstPageFrames[0], minX: 12, width: 178)
        expectHorizontalFrame(firstPageFrames[1], minX: 200, width: 216)

        let secondPageFrames = await pagerFrames(progress: 1)
        expectHorizontalFrame(secondPageFrames[0], minX: -176, width: 178)
        expectHorizontalFrame(secondPageFrames[1], minX: 12, width: 216)
    }

    @MainActor
    private func pagerFrames(progress: CGFloat) async -> [Int: CGRect] {
        let capture = PageFrameCapture()
        var layout = PagingHStack(
            spacing: 10,
            pageTrailingInset: 38,
            selection: 0
        )
        layout.animatableData = progress

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
