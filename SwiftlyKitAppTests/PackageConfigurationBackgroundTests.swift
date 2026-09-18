import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

@Suite(.serialized)
struct PackageConfigurationBackgroundTests {

    @MainActor
    @Test
    func keepsBodyBackgroundAttachedToDividerWhenTransformed() throws {
        let size = CGSize(width: 476, height: 178)
        let hostingView = NSHostingView(
            rootView: AnyView(
                ZStack {
                    Color(nsColor: .windowBackgroundColor)
                    PackageConfigurationPage(onContentHeightChange: { _ in })
                        .frame(width: size.width, height: size.height)
                        .geometryGroup()
                        .deemphasiseContent(when: true)
                        .scaleEffect(0.9, anchor: .bottomLeading)
                        .rotationEffect(.degrees(0.8), anchor: .bottomLeading)
                        .offset(x: 2, y: -2)
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

        let dividerProbeX: CGFloat = 90
        let bodyColor = try #require(
            color(at: CGPoint(x: dividerProbeX, y: 100), in: representation, viewSize: size)
        )
        let dividerRange = 50...85
        let dividerY = try #require(
            dividerRange.max { firstY, secondY in
                let firstColor = color(
                    at: CGPoint(x: dividerProbeX, y: CGFloat(firstY)),
                    in: representation,
                    viewSize: size
                )
                let secondColor = color(
                    at: CGPoint(x: dividerProbeX, y: CGFloat(secondY)),
                    in: representation,
                    viewSize: size
                )
                return luminance(firstColor) < luminance(secondColor)
            }
        )
        let bodyStartY = try #require(
            ((dividerY + 1)...100).first { y in
                guard let sample = color(
                    at: CGPoint(x: dividerProbeX, y: CGFloat(y)),
                    in: representation,
                    viewSize: size
                ) else {
                    return false
                }
                return colorDistance(sample, bodyColor) < 0.01
            }
        )

        #expect(
            bodyStartY - dividerY <= 2,
            "Divider row: \(dividerY), body background row: \(bodyStartY)"
        )
    }

    @MainActor
    @Test
    func fillsExtraHeightBelowConfigurationContent() throws {
        let size = CGSize(width: 620, height: 280)
        let hostingView = NSHostingView(
            rootView: AnyView(
                ZStack {
                    Color(nsColor: .windowBackgroundColor)
                    PackageConfigurationPage(onContentHeightChange: { _ in })
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

    @MainActor
    @Test
    func reportsContentHeightIndependentlyOfPresentedHeight() async throws {
        let compactHeight = try await reportedPackageConfigurationHeight(
            for: CGSize(width: 620, height: 220)
        )
        let expandedHeight = try await reportedPackageConfigurationHeight(
            for: CGSize(width: 620, height: 280)
        )

        #expect(
            abs(compactHeight - expandedHeight) < 0.5,
            "Compact allocation: \(compactHeight), expanded allocation: \(expandedHeight)"
        )
    }

    @MainActor
    @Test
    func reportsResponsiveHeightWhenWidthChangesAndRestores() async throws {
        let heights = try await reportedPackageConfigurationHeights(
            for: [620, 360, 620],
            presentedHeight: 280
        )
        let wideHeight = heights[0]
        let narrowHeight = heights[1]
        let restoredWideHeight = heights[2]

        #expect(
            narrowHeight > wideHeight + 40,
            "Wide height: \(wideHeight), narrow height: \(narrowHeight)"
        )
        #expect(abs(restoredWideHeight - wideHeight) < 0.5)
    }

    @MainActor
    @Test
    func acceptsIntermediateHeightWithoutLosingContentMeasurement() async throws {
        let contentHeight = HeightCapture()
        let surfaceHeight = HeightCapture()
        let allocatedHeight: CGFloat = 180
        let size = CGSize(width: 360, height: allocatedHeight)
        let hostingView = NSHostingView(
            rootView: PackageConfigurationPage { contentHeight.height = $0 }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                    surfaceHeight.height = $0
                }
                .frame(width: size.width, height: size.height, alignment: .top)
                .clipped()
                .environment(PackageModel())
                .environment(BuildOptions())
        )
        hostingView.frame = CGRect(origin: .zero, size: size)

        for _ in 0..<10 {
            hostingView.layoutSubtreeIfNeeded()
            await Task.yield()
        }

        let measuredSurfaceHeight = try #require(surfaceHeight.height)
        let measuredContentHeight = try #require(contentHeight.height)
        #expect(abs(measuredSurfaceHeight - allocatedHeight) < 0.5)
        #expect(measuredContentHeight > allocatedHeight + 40)
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

    private func luminance(_ color: NSColor?) -> CGFloat {
        guard let color = color?.usingColorSpace(.deviceRGB) else {
            return 0
        }
        return 0.2126 * color.redComponent
            + 0.7152 * color.greenComponent
            + 0.0722 * color.blueComponent
    }

}

@MainActor
func reportedPackageConfigurationHeight(
    for size: CGSize
) async throws -> CGFloat {
    let capture = HeightCapture()
    let hostingView = NSHostingView(
        rootView: AnyView(
            PackageConfigurationPage { capture.height = $0 }
                .preferredColorScheme(.dark)
                .environment(PackageModel())
                .environment(BuildOptions())
                .frame(width: size.width, height: size.height)
        )
    )
    hostingView.frame = CGRect(origin: .zero, size: size)

    for _ in 0..<10 {
        hostingView.layoutSubtreeIfNeeded()
        hostingView.displayIfNeeded()
        await Task.yield()
    }

    return try #require(capture.height)
}

@MainActor
private func reportedPackageConfigurationHeights(
    for widths: [CGFloat],
    presentedHeight: CGFloat
) async throws -> [CGFloat] {
    let capture = HeightCapture()
    let hostingView = NSHostingView(
        rootView: AnyView(
            PackageConfigurationPage { capture.height = $0 }
                .preferredColorScheme(.dark)
                .environment(PackageModel())
                .environment(BuildOptions())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    )
    var heights = [CGFloat]()

    for width in widths {
        capture.height = nil
        hostingView.frame = CGRect(
            origin: .zero,
            size: CGSize(width: width, height: presentedHeight)
        )

        for _ in 0..<10 {
            hostingView.layoutSubtreeIfNeeded()
            hostingView.displayIfNeeded()
            await Task.yield()
        }

        heights.append(try #require(capture.height))
    }

    return heights
}

@MainActor
private final class HeightCapture {

    var height: CGFloat?

}
