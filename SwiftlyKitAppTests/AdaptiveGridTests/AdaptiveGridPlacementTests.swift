import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

extension AdaptiveGridTests {

    @MainActor
    @Test
    func oneColumnRowsUsePrecedingRowHeightsAndSpacing() async throws {
        let snapshot = try await snapshot(
            width: 317,
            firstLabelHeight: 20,
            firstControlHeight: 40,
            secondLabelHeight: 20,
            secondControlHeight: 20
        )

        #expect(snapshot.arrangement == .oneColumn)
        #expect(abs(snapshot.gridSize.height - 72) < 0.5)
        #expect(abs(snapshot.frame(field: 1, part: .label).minY - 52) < 0.5)
        #expect(abs(snapshot.frame(field: 1, part: .control).minY - 52) < 0.5)
        #expect(
            abs(
                snapshot.frame(field: 0, part: .label).midY
                    - snapshot.frame(field: 0, part: .control).midY
            ) < 0.5
        )
        #expect(
            abs(
                snapshot.frame(field: 1, part: .label).midY
                    - snapshot.frame(field: 1, part: .control).midY
            ) < 0.5
        )
    }

}
