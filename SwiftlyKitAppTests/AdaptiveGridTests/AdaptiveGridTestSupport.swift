import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

extension AdaptiveGridTests {

    @MainActor
    func snapshot(
        width: CGFloat,
        secondControlWidth: CGFloat = 100,
        firstLabelHeight: CGFloat = 20,
        firstControlHeight: CGFloat = 20,
        secondLabelHeight: CGFloat = 20,
        secondControlHeight: CGFloat = 20
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
                size: CGSize(width: 50, height: secondLabelHeight),
                capture: capture
            )
            AdaptiveGridProbe(
                field: 1,
                part: .control,
                size: CGSize(width: secondControlWidth, height: secondControlHeight),
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
            capture.record($0)
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
    func persistentGrid() -> (
        NSHostingView<AnyView>,
        AdaptiveGridCapture
    ) {
        let capture = AdaptiveGridCapture()
        let rootView = AdaptiveGrid {
            AdaptiveGridProbe(
                field: 0,
                part: .label,
                size: CGSize(width: 40, height: 20),
                capture: capture
            )
            AdaptiveGridProbe(
                field: 0,
                part: .control,
                size: CGSize(width: 80, height: 20),
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
                size: CGSize(width: 100, height: 20),
                capture: capture
            )
        }
        .publishesAdaptiveGridMetrics()
        .onGeometryChange(for: CGSize.self) { $0.size } action: {
            capture.record(gridSize: $0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .coordinateSpace(.named("AdaptiveGridTests"))
        .onAdaptiveGridArrangementChange {
            capture.record($0)
        }

        return (NSHostingView(rootView: AnyView(rootView)), capture)
    }

    @MainActor
    func resizeSnapshot(
        _ hostingView: NSHostingView<AnyView>,
        capture: AdaptiveGridCapture,
        width: CGFloat,
        expectedArrangement: AdaptiveGridArrangement
    ) async throws -> AdaptiveGridSnapshot {
        let startingRevision = capture.revision
        hostingView.frame = CGRect(x: 0, y: 0, width: width, height: 200)
        hostingView.needsLayout = true
        var previousSnapshot: AdaptiveGridSnapshot?
        var stableReadingCount = 0

        for _ in 0..<100 {
            hostingView.layoutSubtreeIfNeeded()
            await Task.yield()

            if
                capture.revision > startingRevision,
                capture.arrangement == expectedArrangement,
                capture.frames.count == 4,
                let gridSize = capture.gridSize,
                abs(gridSize.width - width) < 0.5
            {
                let snapshot = AdaptiveGridSnapshot(
                    arrangement: expectedArrangement,
                    frames: capture.frames,
                    gridSize: gridSize
                )

                if
                    let previousSnapshot,
                    snapshot.frames == previousSnapshot.frames,
                    snapshot.gridSize == previousSnapshot.gridSize
                {
                    stableReadingCount += 1
                    if stableReadingCount == 2 { return snapshot }
                } else {
                    stableReadingCount = 0
                    previousSnapshot = snapshot
                }
            }

            try? await Task.sleep(for: .milliseconds(2))
        }

        throw AdaptiveGridWaitTimeout(
            "Grid did not settle at width \(width). Expected arrangement: "
                + "\(expectedArrangement); actual events: \(capture.arrangementEvents); "
                + "actual grid size: \(String(describing: capture.gridSize)); "
                + "captured frames: \(capture.frames)."
        )
    }

    @MainActor
    func expectNoAdjacentDuplicateArrangements(
        _ arrangements: [AdaptiveGridArrangement]
    ) {
        #expect(arrangements.count >= 3)

        for (previous, current) in zip(arrangements, arrangements.dropFirst()) {
            let isDuplicate = switch (previous, current) {
            case (.oneColumn, .oneColumn), (.twoColumns, .twoColumns): true
            default: false
            }
            #expect(!isDuplicate, "Arrangement events: \(arrangements)")
        }
    }

    @MainActor
    func reportedPackageArrangement(
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
final class AdaptiveGridCapture {

    var arrangement: AdaptiveGridArrangement?
    var arrangementEvents: [AdaptiveGridArrangement] = []
    var frames: [AdaptiveGridProbe.ID: CGRect] = [:]
    var gridSize: CGSize?
    var revision = 0

    func record(_ arrangement: AdaptiveGridArrangement) {
        self.arrangement = arrangement
        arrangementEvents.append(arrangement)
        revision += 1
    }

    func record(gridSize: CGSize) {
        self.gridSize = gridSize
        revision += 1
    }

    func record(frame: CGRect, for id: AdaptiveGridProbe.ID) {
        frames[id] = frame
        revision += 1
    }

}

@MainActor
final class PackageArrangementCapture {

    var arrangement: AdaptiveGridArrangement?

}

struct AdaptiveGridSnapshot {

    let arrangement: AdaptiveGridArrangement
    let frames: [AdaptiveGridProbe.ID: CGRect]
    let gridSize: CGSize

    func labelFrame(for field: Int) -> CGRect {
        frame(field: field, part: .label)
    }

    func frame(field: Int, part: AdaptiveGridProbe.Part) -> CGRect {
        frames[AdaptiveGridProbe.ID(field: field, part: part), default: .zero]
    }

}

struct AdaptiveGridProbe: View {

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
                capture.record(
                    frame: frame,
                    for: ID(field: field, part: part)
                )
            }
    }

    enum Part: Hashable {
        case label
        case control
    }

    struct ID: Hashable {
        let field: Int
        let part: Part
    }

}

struct AdaptiveGridWaitTimeout: Error, CustomStringConvertible {

    let description: String

    init(_ description: String) {
        self.description = description
    }

}
