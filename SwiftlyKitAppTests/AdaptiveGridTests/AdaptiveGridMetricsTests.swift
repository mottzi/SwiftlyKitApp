import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

extension AdaptiveGridTests {

    @MainActor
    @Test
    func packageConfiguratorReportsItsVisibleArrangement() async throws {
        let wide = try await reportedPackageArrangement(width: 620)
        let narrow = try await reportedPackageArrangement(width: 276)

        #expect(wide == .twoColumns)
        #expect(narrow == .oneColumn)
    }

}
