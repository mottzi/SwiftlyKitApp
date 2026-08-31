import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

@Suite(.serialized)
struct AdaptiveGridTests {
}

extension AdaptiveGridTests {

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
    func rowHeightUsesTallerControl() async throws {
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
    func rowHeightUsesTallerLabel() async throws {
        let snapshot = try await snapshot(
            width: 318,
            firstLabelHeight: 40,
            firstControlHeight: 20
        )

        #expect(abs(snapshot.gridSize.height - 40) < 0.5)
        #expect(
            abs(
                snapshot.frame(field: 0, part: .label).midY
                    - snapshot.frame(field: 0, part: .control).midY
            ) < 0.5
        )
    }

}
