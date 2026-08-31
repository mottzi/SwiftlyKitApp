import SwiftlyKit
import Testing
@testable import SwiftlyKitApp

struct BuildOptionsTests {

    @MainActor
    @Test
    func packageSessionDiscardClearsWorkflowOutputAndPreservesBuildPreferences() {
        let buildOptions = BuildOptions()
        buildOptions.target = .linux(.arm64)
        buildOptions.configuration = .debug
        buildOptions.toolchain = .exact(SwiftVersion(major: 6, minor: 2, patch: 0))
        buildOptions.stripBinary = true
        buildOptions.buildWorkflow.log.append("Previous package failure", kind: .failure)

        buildOptions.clearPackageSession()

        #expect(buildOptions.buildWorkflow.state == .idle)
        #expect(buildOptions.buildWorkflow.log.entries.isEmpty)
        #expect(buildOptions.target == .linux(.arm64))
        #expect(buildOptions.toolchain == .automatic)
        #expect(buildOptions.stripBinary)

        guard case .debug = buildOptions.configuration else {
            Issue.record("Discarding a package session must preserve the build configuration.")
            return
        }
    }

}
