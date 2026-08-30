import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

@Suite(.serialized)
struct PackageConfigurationBackgroundTests {

    @MainActor
    @Test
    func fillsExtraHeightBelowConfigurationContent() throws {
        let size = CGSize(width: 620, height: 280)
        let hostingView = NSHostingView(
            rootView: AnyView(
                ZStack {
                    Color(nsColor: .windowBackgroundColor)
                    PackageConfigurationPage(onIdealHeightChange: { _ in })
                        .frame(width: size.width, height: size.height)
                }
                .preferredColorScheme(.dark)
                .environment(PackageModel())
                .environment(BuildOptions())
                .frame(width: size.width, height: size.height)
            )
        )
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()
        hostingView.displayIfNeeded()

        let representation = try #require(
            hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)
        )
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)

        let configurationColor = try #require(
            color(at: CGPoint(x: size.width / 2, y: 70), in: representation, viewSize: size)
        )
        let lowerEdgeColor = try #require(
            color(at: CGPoint(x: size.width / 2, y: size.height - 8), in: representation, viewSize: size)
        )

        #expect(
            colorDistance(configurationColor, lowerEdgeColor) < 0.01,
            "Configuration color: \(configurationColor), lower edge color: \(lowerEdgeColor)"
        )
    }

    private func color(
        at point: CGPoint,
        in representation: NSBitmapImageRep,
        viewSize: CGSize
    ) -> NSColor? {

        let x = Int(point.x * CGFloat(representation.pixelsWide) / viewSize.width)
        let y = Int(point.y * CGFloat(representation.pixelsHigh) / viewSize.height)
        return representation.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB)
    }

    private func colorDistance(_ first: NSColor, _ second: NSColor) -> CGFloat {
        abs(first.redComponent - second.redComponent)
            + abs(first.greenComponent - second.greenComponent)
            + abs(first.blueComponent - second.blueComponent)
            + abs(first.alphaComponent - second.alphaComponent)
    }

}
