import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

@Suite(.serialized)
struct AdaptiveGridTests {

    @MainActor
    @Test
    func choosesColumnsFromRealIntrinsicFieldWidths() async throws {
        let threshold = CGFloat(318)

        let narrow = try await snapshot(width: threshold - 1)
        let fitting = try await snapshot(width: threshold)

        #expect(narrow.arrangement == .oneColumn)
        #expect(fitting.arrangement == .twoColumns)
        #expect(abs(narrow.labelFrame(for: 1).minY - narrow.labelFrame(for: 0).minY) > 1)
        #expect(abs(fitting.labelFrame(for: 1).minY - fitting.labelFrame(for: 0).minY) < 0.5)
    }

    @MainActor
    @Test
    func intrinsicWidthChangesTheColumnThresholdNaturally() async throws {
        let ordinary = try await snapshot(width: 318)
        let widerControl = try await snapshot(width: 318, secondControlWidth: 101)

        #expect(ordinary.arrangement == .twoColumns)
        #expect(widerControl.arrangement == .oneColumn)
    }

    @MainActor
    @Test
    func rowHeightUsesTheTallerLabelOrControl() async throws {
        let snapshot = try await snapshot(
            width: 318,
            firstLabelHeight: 20,
            firstControlHeight: 40
        )

        #expect(abs(snapshot.gridSize.height - 40) < 0.5)
        #expect(
            abs(
                snapshot.frame(field: 0, part: .label).midY
                    - snapshot.frame(field: 0, part: .control).midY
            ) < 0.5
        )
    }

    @MainActor
    @Test
    func wideNarrowWideRestoresArrangementAndGeometry() async throws {
        let wide = try await snapshot(width: 318)
        let narrow = try await snapshot(width: 317)
        let restored = try await snapshot(width: 318)

        #expect(wide.arrangement == .twoColumns)
        #expect(narrow.arrangement == .oneColumn)
        #expect(restored.arrangement == .twoColumns)
        #expect(wide.frames == restored.frames)
        #expect(wide.gridSize == restored.gridSize)
    }

    @MainActor
    @Test
    func packageConfiguratorReportsItsVisibleArrangement() async throws {
        let wide = try await reportedPackageArrangement(width: 620)
        let narrow = try await reportedPackageArrangement(width: 276)

        #expect(wide == .twoColumns)
        #expect(narrow == .oneColumn)
    }

    @MainActor
    private func snapshot(
        width: CGFloat,
        secondControlWidth: CGFloat = 100,
        firstLabelHeight: CGFloat = 20,
        firstControlHeight: CGFloat = 20
    ) async throws -> AdaptiveGridSnapshot {
        let capture = AdaptiveGridCapture()
        let rootView = AdaptiveGrid {
            AdaptiveGridProbe(
                field: 0,
                part: .label,
                size: CGSize(width: 40, height: firstLabelHeight),
                capture: capture
            )
            AdaptiveGridProbe(
                field: 0,
                part: .control,
                size: CGSize(width: 80, height: firstControlHeight),
                capture: capture
            )
            AdaptiveGridProbe(
                field: 1,
                part: .label,
                size: CGSize(width: 50, height: 20),
                capture: capture
            )
            AdaptiveGridProbe(
                field: 1,
                part: .control,
                size: CGSize(width: secondControlWidth, height: 20),
                capture: capture
            )
        }
        .publishesAdaptiveGridMetrics()
        .onGeometryChange(for: CGSize.self) { $0.size } action: {
            capture.gridSize = $0
        }
        .frame(width: width, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .coordinateSpace(.named("AdaptiveGridTests"))
        .onAdaptiveGridArrangementChange {
            capture.arrangement = $0
        }

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = CGRect(x: 0, y: 0, width: width, height: 200)

        for _ in 0..<10 where capture.arrangement == nil
                || capture.frames.count < 4
                || capture.gridSize == nil {
            hostingView.layoutSubtreeIfNeeded()
            await Task.yield()
        }

        let frames = capture.frames

        return AdaptiveGridSnapshot(
            arrangement: try #require(capture.arrangement),
            frames: frames,
            gridSize: try #require(capture.gridSize)
        )
    }

    @MainActor
    private func reportedPackageArrangement(
        width: CGFloat
    ) async throws -> AdaptiveGridArrangement {
        let capture = PackageArrangementCapture()
        let rootView = PackageConfigurator()
            .environment(PackageModel())
            .environment(BuildOptions())
            .frame(width: width)
            .onAdaptiveGridArrangementChange {
                capture.arrangement = $0
            }
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = CGRect(x: 0, y: 0, width: width, height: 300)

        for _ in 0..<10 where capture.arrangement == nil {
            hostingView.layoutSubtreeIfNeeded()
            await Task.yield()
        }

        return try #require(capture.arrangement)
    }

}

@MainActor
private final class AdaptiveGridCapture {

    var arrangement: AdaptiveGridArrangement?
    var frames: [AdaptiveGridProbe.ID: CGRect] = [:]
    var gridSize: CGSize?

}

@MainActor
private final class PackageArrangementCapture {

    var arrangement: AdaptiveGridArrangement?

}

private struct AdaptiveGridSnapshot {

    let arrangement: AdaptiveGridArrangement
    let frames: [AdaptiveGridProbe.ID: CGRect]
    let gridSize: CGSize

    func frame(field: Int, part: AdaptiveGridProbe.Part) -> CGRect {
        frames[AdaptiveGridProbe.ID(field: field, part: part), default: .zero]
    }

    func labelFrame(for field: Int) -> CGRect {
        frame(field: field, part: .label)
    }

}

private struct AdaptiveGridProbe: View {

    enum Part: Hashable {
        case label
        case control
    }

    struct ID: Hashable {
        let field: Int
        let part: Part
    }

    let field: Int
    let part: Part
    let size: CGSize
    let capture: AdaptiveGridCapture

    var body: some View {
        Color.clear
            .frame(width: size.width, height: size.height)
            .onGeometryChange(for: CGRect.self) { geometry in
                geometry.frame(in: .named("AdaptiveGridTests"))
            } action: { frame in
                capture.frames[ID(field: field, part: part)] = frame
            }
    }

}
