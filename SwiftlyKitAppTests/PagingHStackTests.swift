import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

@Suite(.serialized)
struct PagingHStackTests {

    @MainActor
    @Test
    func usesTallestIntrinsicPageHeightWithoutAFiniteProposal() {
        let hostingView = NSHostingView(
            rootView: PagingHStack(spacing: 10, selection: 0) {
                Color.red.frame(width: 100, height: 40)
                Color.blue.frame(width: 120, height: 70)
            }
        )

        #expect(abs(hostingView.fittingSize.height - 70) < 0.5)
    }

    @MainActor
    @Test
    func remeasuresIntrinsicPageHeightWhenViewportWidthChanges() {
        let wideHeight = pagerFittingHeight(width: 240)
        let narrowHeight = pagerFittingHeight(width: 140)

        #expect(narrowHeight > wideHeight + 30)
    }

    @MainActor
    private func pagerFittingHeight(width: CGFloat) -> CGFloat {
        let hostingView = NSHostingView(
            rootView: PagingHStack(spacing: 10, selection: 0) {
                WidthResponsivePage() {
                    Color.clear
                }
                Color.clear.frame(height: 40)
            }
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
        )

        return hostingView.fittingSize.height
    }

    @MainActor
    @Test
    func honorsFiniteHeightProposal() async throws {
        let capture = PageSizeCapture()
        let hostingView = NSHostingView(
            rootView: PagingHStack(spacing: 10, selection: 0) {
                Color.red.frame(height: 100)
                Color.blue.frame(height: 140)
            }
            .onGeometryChange(for: CGSize.self) { $0.size } action: {
                capture.size = $0
            }
            .frame(width: 240, height: 60)
        )
        hostingView.frame = CGRect(x: 0, y: 0, width: 240, height: 60)

        let size = try await reportedSize(capture, in: hostingView)

        #expect(abs(size.height - 60) < 0.5)
    }

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

    @MainActor
    private func reportedSize(
        _ capture: PageSizeCapture,
        in hostingView: NSHostingView<some View>
    ) async throws -> CGSize {
        for _ in 0..<10 where capture.size == nil {
            hostingView.layoutSubtreeIfNeeded()
            await Task.yield()
        }

        return try #require(capture.size)
    }

}

@MainActor
private final class PageFrameCapture {

    var frames: [Int: CGRect] = [:]

}

@MainActor
private final class PageSizeCapture {

    var size: CGSize?

}

private struct WidthResponsivePage: Layout {

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? 100
        return CGSize(width: width, height: width < 180 ? 100 : 50)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {}

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
