import AppKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

struct SectionHeaderGeometryTests {

    @MainActor
    @Test
    func packageAndBuildHeadersUseMatchingHeights() {
        let packageHeader = NSHostingView(
            rootView: AnyView(
                PackageHeader()
                    .environment(PackageModel())
                    .environment(BuildOptions())
            )
        )
        let buildHeader = NSHostingView(
            rootView: AnyView(
                BuildStatus(
                    state: .idle,
                    result: nil,
                    readyDetail: nil,
                    onCancel: {}
                )
            )
        )

        #expect(abs(packageHeader.fittingSize.height - 48) < 0.5)
        #expect(abs(buildHeader.fittingSize.height - 48) < 0.5)
        #expect(abs(packageHeader.fittingSize.height - buildHeader.fittingSize.height) < 0.5)
    }

}
