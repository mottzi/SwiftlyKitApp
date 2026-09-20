import SwiftlyKit
import Testing
@testable import SwiftlyKitApp

@MainActor
struct BuildFeedbackTests {

    @Test
    func failureSummarySelectsFirstSourceErrorAndPreservesRawFailure() {
        let detail = """
        SwiftPM could not build the executable: Building for production...
        error: emit-module command failed with exit code 1
        /tmp/Example/Sources/main.swift:1:1: warning: unused value
        /tmp/Example/Sources/main.swift:2:7: error: cannot find 'missingAuditSymbol' in scope
        2 | print(missingAuditSymbol)
        /tmp/Example/Sources/main.swift:3:7: error: another error
        """
        let state = BuildWorkflowState.failed(detail)

        #expect(state.failureSummary == "Cannot find 'missingAuditSymbol' in scope")
        #expect(state == .failed(detail))
    }

    @Test
    func failureSummaryFallsBackWithoutSourceDiagnostic() {
        let detail = "The selected product's runtime resource output could not be verified."
        #expect(BuildWorkflowState.failed(detail).failureSummary == detail)
        #expect(BuildWorkflowState.idle.failureSummary == nil)
    }

    @Test
    func failureSummarySkipsEmptySourceDiagnostic() {
        let detail = "/tmp/main.swift:1:1: error: \n/tmp/main.swift:2:1: fatal error: module is unavailable"
        #expect(BuildWorkflowState.failed(detail).failureSummary == "Module is unavailable")
    }

    @Test
    func libraryOnlyPackageExplainsTheBlockerWithoutAnotherSelectionPath() {
        let status = BuildSetupStatus.current(host: .ready, toolchain: .ready([]), product: .empty)

        #expect(status.title == "No executable products")
        #expect(status.detail == "This package has no executable product to build.")
        #expect(status.action == nil)
        #expect(!status.showsProgress)
    }

    @Test
    func setupShowsTheFirstIncompleteStage() {
        let host = BuildSetupStatus.current(host: .checking, toolchain: .ready([]), product: .empty)
        let toolchain = BuildSetupStatus.current(host: .ready, toolchain: .discovering, product: .empty)
        let product = BuildSetupStatus.current(
            host: .ready,
            toolchain: .ready([]),
            product: .discovering(detail: "Installing Swift 6.2.")
        )

        #expect(host.title == "Checking developer tools")
        #expect(toolchain.title == "Checking Swift compatibility")
        #expect(product.detail == "Installing Swift 6.2.")
        #expect(host.showsProgress && toolchain.showsProgress && product.showsProgress)
    }

    @Test
    func installationStatusReturnsToCheckingAfterPreparation() {

        let installation = BuildSetupStatus.current(
            host: .ready,
            toolchain: .ready([]),
            product: .discovering(
                detail: "Downloading and installing the toolchain.",
                installationTitle: "Installing Swift 6.4.0"
            )
        )
        let inspection = BuildSetupStatus.current(
            host: .ready,
            toolchain: .ready([]),
            product: .discovering(detail: "Inspecting executable package products.")
        )

        #expect(installation.isInstalling)
        #expect(installation.title == "Installing Swift 6.4.0")
        #expect(installation.showsProgress)
        #expect(!inspection.isInstalling)
        #expect(inspection.showsProgress)
        #expect(installation.action == nil)
    }

    @Test
    func completedBuildIdentityDoesNotFollowCurrentChoices() {
        let options = BuildOptions()
        let identity = BuildIdentity(
            product: "Example",
            target: options.target,
            configuration: options.configuration,
            swiftVersion: SwiftVersion(major: 6, minor: 3, patch: 3),
            stripBinary: options.stripBinary
        )

        options.target = .linux(.arm64)
        options.configuration = .debug
        options.stripBinary = true

        #expect(identity.summary == "Example · x86_64 Linux · Release · Swift 6.3.3")
        #expect(!identity.stripBinary)
    }

    @Test
    func setupFailuresAndInstallationRequestsDoNotUseProgressPresentation() {
        let failure = BuildSetupStatus.current(
            host: .ready,
            toolchain: .failed("Unable to inspect package"),
            product: .idle
        )
        let installation = BuildSetupStatus.current(
            host: .commandLineToolsRequired,
            toolchain: .idle,
            product: .idle
        )

        #expect(!failure.showsProgress)
        #expect(failure.action == .swiftDetails)
        #expect(!installation.showsProgress)
        #expect(installation.action == .swiftDetails)
    }

}
