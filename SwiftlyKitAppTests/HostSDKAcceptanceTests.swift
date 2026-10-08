import Foundation
import SwiftlyKit
import Testing
@testable import SwiftlyKitApp

@MainActor
struct HostSDKAcceptanceTests {

    @Test(
        "Deployer is ready only after dependency inspection and builds with its exact selected Swift version",
        .enabled(
            if: ProcessInfo.processInfo.environment["SWIFTLYKIT_DEPLOYER_PACKAGE"] != nil,
            "Set SWIFTLYKIT_DEPLOYER_PACKAGE to run the real app workflow against Deployer."
        )
    )
    func deployerReadinessAndBuild() async throws {
        let path = try #require(ProcessInfo.processInfo.environment["SWIFTLYKIT_DEPLOYER_PACKAGE"])
        let root = URL(filePath: path)
        let kit = SwiftlyKit()
        let version = SwiftVersion(major: 6, minor: 3, patch: 3)
        let selection = ToolchainSelection.exact(version)
        let choices = try await kit.compatibleEnvironments(root, for: .linux(.x86_64))
        let assessment = try choices.select(selection)
        try #require(!assessment.requiresInstallation, "This test requires the selected toolchain and Linux SDK installed.")
        let discovery = ProductDiscovery(swiftlyKit: kit)
        await discovery.discover(in: root, for: .linux(.x86_64), toolchain: selection, environmentChoices: choices)
        #expect(discovery.state == .ready)
        let prepared = try #require(discovery.preparedPackage(in: root, for: .linux(.x86_64), toolchain: selection))
        #expect(prepared.environment.swiftVersion == version)
        #expect(prepared.environment.hostSDKVersion != nil)
        #expect(prepared.environment.hostSDKVersion == "26.5")
        await discovery.discover(in: root, for: .linux(.x86_64), toolchain: selection, environmentChoices: choices)
        #expect(discovery.state == .ready)
        let repeated = try #require(discovery.preparedPackage(in: root, for: .linux(.x86_64), toolchain: selection))
        #expect(repeated.environment.swiftVersion == version)
        #expect(repeated.environment.hostSDKVersion == prepared.environment.hostSDKVersion)
        let workflow = BuildWorkflow(swiftlyKit: kit)
        workflow.start(prepared, target: .linux(.x86_64), configuration: .release, stripBinary: true)
        let deadline = Date().addingTimeInterval(900)
        while workflow.isRunning, Date() < deadline {
            try await Task.sleep(for: .milliseconds(100))
        }
        if workflow.isRunning { workflow.cancel() }
        #expect(workflow.state == .succeeded, Comment(rawValue: workflow.log.text))
        let result = try #require(workflow.result)
        #expect(result.executableName == "deployer")
        #expect(workflow.identity?.swiftVersion == version)
        #expect(workflow.log.text.contains("macOS SDK"))
        #expect(FileManager.default.isExecutableFile(atPath: result.executable.path(percentEncoded: false)))
    }

}
