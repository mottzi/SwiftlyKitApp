import Foundation
import SwiftlyKit
import Testing
@testable import SwiftlyKitApp

@MainActor
struct HostSDKAcceptanceTests {

    @Test(
        "Deployer configures first, then validates dependencies and builds with exact Swift 6.3.3",
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
        #expect(discovery.state == .configured)
        let prepared = try #require(discovery.preparedPackage(in: root, for: .linux(.x86_64), toolchain: selection))
        #expect(prepared.environment.swiftVersion == version)
        #expect(prepared.environment.hostSDKVersion != nil)
        await discovery.discover(in: root, for: .linux(.x86_64), toolchain: selection, environmentChoices: choices)
        #expect(discovery.state == .configured)
        let repeated = try #require(discovery.preparedPackage(in: root, for: .linux(.x86_64), toolchain: selection))
        #expect(repeated.environment.swiftVersion == version)
        #expect(repeated.environment.hostSDKVersion == prepared.environment.hostSDKVersion)
        let workflow = BuildWorkflow(swiftlyKit: kit)
        workflow.start(prepared, target: .linux(.x86_64), configuration: .release, stripBinary: true)
        while !workflow.log.text.contains("Inspecting package dependencies"), workflow.isRunning {
            try await Task.sleep(for: .milliseconds(10))
        }
        let configurationStarted = ContinuousClock.now
        let duringBuild = try await kit.configurePackage(using: prepared.environment)
        #expect(duringBuild.environment.swiftVersion == version)
        #expect(duringBuild.products.map(\.name) == ["deployer"])
        #expect(configurationStarted.duration(to: .now) < .seconds(5),
            "Root configuration must remain available during dependency validation and compilation.")
        let deadline = Date().addingTimeInterval(900)
        while workflow.isRunning, Date() < deadline {
            try await Task.sleep(for: .milliseconds(100))
        }
        if workflow.isRunning { workflow.cancel() }
        #expect(workflow.state == .succeeded, Comment(rawValue: workflow.log.text))
        #expect(workflow.identity?.swiftVersion == version)
        #expect(workflow.log.text.contains("Using macOS SDK 26.5 with Swift 6.3.3"), "\(workflow.log.text)")
        let result = try #require(workflow.result)
        #expect(result.executableName == "deployer")
        #expect(workflow.log.text.contains("macOS SDK"))
        #expect(FileManager.default.isExecutableFile(atPath: result.executable.path(percentEncoded: false)))
    }

}
