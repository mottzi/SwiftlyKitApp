import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

extension AdaptiveGridTests {

    @MainActor
    @Test
    func displayedArrangementDoesNotOverrideWidthRecommendation() async throws {
        let wide = try await snapshot(width: 318, arrangement: .oneColumn)
        #expect(wide.arrangement == .twoColumns)
        #expect(wide.labelFrame(for: 1).minY > wide.labelFrame(for: 0).minY)

        let narrow = try await snapshot(width: 317, arrangement: .twoColumns)
        #expect(narrow.arrangement == .oneColumn)
        #expect(abs(narrow.labelFrame(for: 1).minY - narrow.labelFrame(for: 0).minY) < 0.5)
    }


    @MainActor
    @Test
    func onePersistentGridRestoresWideGeometryAfterNarrowResize() async throws {
        let (hostingView, capture) = persistentGrid()
        let wide = try await resizeSnapshot(
            hostingView,
            capture: capture,
            width: 318,
            expectedArrangement: .twoColumns
        )
        _ = try await resizeSnapshot(
            hostingView,
            capture: capture,
            width: 317,
            expectedArrangement: .oneColumn
        )
        let restored = try await resizeSnapshot(
            hostingView,
            capture: capture,
            width: 318,
            expectedArrangement: .twoColumns
        )

        #expect(wide.frames == restored.frames)
        #expect(wide.gridSize == restored.gridSize)
        expectNoAdjacentDuplicateArrangements(capture.arrangementEvents)
    }

    @MainActor
    @Test
    func onePersistentGridRestoresNarrowGeometryAfterWideResize() async throws {
        let (hostingView, capture) = persistentGrid()
        let narrow = try await resizeSnapshot(
            hostingView,
            capture: capture,
            width: 317,
            expectedArrangement: .oneColumn
        )
        _ = try await resizeSnapshot(
            hostingView,
            capture: capture,
            width: 318,
            expectedArrangement: .twoColumns
        )
        let restored = try await resizeSnapshot(
            hostingView,
            capture: capture,
            width: 317,
            expectedArrangement: .oneColumn
        )

        #expect(narrow.frames == restored.frames)
        #expect(narrow.gridSize == restored.gridSize)
        expectNoAdjacentDuplicateArrangements(capture.arrangementEvents)
    }

}
