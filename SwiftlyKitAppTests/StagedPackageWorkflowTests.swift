import AppKit
import Foundation
import Observation
@testable import SwiftlyKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

@MainActor
@Suite("Staged package workflow", .timeLimit(.minutes(1)))
struct StagedPackageWorkflowTests {

    @Test("Cancelled discovery delays an update until its work actually returns")
    func cancelledDiscoveryDelaysUpdate() async throws {

        let fixture = try StagedPackageFixture()
        defer { fixture.remove() }
        let activity = AppActivity()
        let gate = WorkflowGate()
        let choices = fixture.choices()
        var operations = fixture.discoveryOperations()
        operations.compatibleEnvironments = { _, _ in
            await gate.wait()
            return choices
        }
        let options = BuildOptions(discoveryOperations: operations, activity: activity)
        let task = Task {
            await options.discoverPackage(in: fixture.root, for: .linux(.x86_64), toolchain: .automatic)
        }
        await gate.waitForEntry()
        var restarted = false
        activity.whenIdle { restarted = true }

        task.cancel()
        options.clearPackageSession()
        #expect(activity.isBusy)
        #expect(!restarted)

        await gate.open()
        await task.value
        #expect(!activity.isBusy)
        #expect(restarted)
    }

    @Test("Build work blocks restart before its task starts and until cancellation finishes")
    func cancelledBuildDelaysUpdate() async throws {

        let fixture = try StagedPackageFixture()
        defer { fixture.remove() }
        let activity = AppActivity()
        let gate = WorkflowGate()
        var operations = fixture.buildOperations()
        operations.build = { _, _, _ in
            await gate.wait()
            try Task.checkCancellation()
            return fixture.result
        }
        let workflow = BuildWorkflow(operations: operations, activity: activity)
        workflow.start(fixture.prepared(), target: .linux(.x86_64), configuration: .release, stripBinary: false)
        #expect(activity.isBusy)

        await gate.waitForEntry()
        var restarted = false
        activity.whenIdle { restarted = true }
        workflow.cancel()
        #expect(!restarted)

        await gate.open()
        await waitUntil { !activity.isBusy }
        #expect(restarted)
        #expect(workflow.state == .cancelled)
    }

    @Test("Selected packages begin discovery before the page transition, while Build waits for both stages")
    func selectionStartsDiscoveryBeforeTransition() async throws {

        let fixture = try StagedPackageFixture()
        defer { fixture.remove() }
        let gate = WorkflowGate()
        let choices = fixture.choices()
        let calls = DiscoveryCallRecorder()
        var operations = fixture.discoveryOperations()
        operations.compatibleEnvironments = { _, _ in
            await calls.record()
            await gate.wait()
            return choices
        }
        let options = BuildOptions(discoveryOperations: operations)
        options.toolchain = .exact(fixture.older)
        let package = PackageModel()
        package.selectPackage(at: fixture.root)
        let hosting = NSHostingView(rootView: AnyView(
            Color.clear.managesPackageDiscovery(packageModel: package, buildOptions: options)
        ))
        hosting.frame = CGRect(x: 0, y: 0, width: 400, height: 200)
        hosting.layoutSubtreeIfNeeded()
        await gate.waitForEntry()

        #expect(!package.isConfigurationReady)
        #expect(!options.canStartBuild(for: package))
        #expect(!options.canEditConfiguration(for: package))
        #expect(options.toolchain == .exact(fixture.older))
        await gate.open()
        await waitUntil { options.productDiscovery.state == .configured }
        let selectedRoot = try #require(package.packageURL)
        #expect(options.preparedPackage(in: selectedRoot) != nil)
        #expect(!options.canStartBuild(for: package))
        #expect(!options.canEditConfiguration(for: package))
        options.startBuild(for: package)
        #expect(options.buildWorkflow.state == .idle)

        package.finishConfigurationTransition()
        #expect(options.canStartBuild(for: package))
        #expect(options.canEditConfiguration(for: package))
        hosting.layoutSubtreeIfNeeded()
        await Task.yield()
        #expect(await calls.count == 1)
        hosting.rootView = AnyView(EmptyView())
    }

    @Test("A completed page transition keeps Build and configuration controls waiting for root discovery")
    func completedTransitionWaitsForConfiguration() async throws {

        let fixture = try StagedPackageFixture()
        defer { fixture.remove() }
        let gate = WorkflowGate()
        let choices = fixture.choices()
        var operations = fixture.discoveryOperations()
        operations.compatibleEnvironments = { _, _ in
            await gate.wait()
            return choices
        }
        let options = BuildOptions(discoveryOperations: operations)
        let package = PackageModel()
        package.selectPackage(at: fixture.root)
        package.finishConfigurationTransition()
        let selectedRoot = try #require(package.packageURL)
        let task = Task {
            await options.discoverPackage(in: selectedRoot, for: .linux(.x86_64), toolchain: .automatic)
        }
        await gate.waitForEntry()
        #expect(!options.canStartBuild(for: package))
        #expect(!options.canEditConfiguration(for: package))
        await gate.open()
        await task.value
        #expect(options.canStartBuild(for: package))
        #expect(options.canEditConfiguration(for: package))
    }

    @Test("The initial unselected task preserves a requested exact toolchain")
    func initialTaskPreservesToolchain() async throws {

        let fixture = try StagedPackageFixture()
        defer { fixture.remove() }
        let options = BuildOptions(discoveryOperations: fixture.discoveryOperations())
        options.toolchain = .exact(fixture.older)
        let package = PackageModel()
        let hosting = NSHostingView(rootView: AnyView(
            Color.clear.managesPackageDiscovery(packageModel: package, buildOptions: options)
        ))
        hosting.frame = CGRect(x: 0, y: 0, width: 400, height: 200)
        hosting.layoutSubtreeIfNeeded()
        await Task.yield()
        #expect(options.toolchain == .exact(fixture.older))
        package.selectPackage(at: fixture.root)
        hosting.layoutSubtreeIfNeeded()
        await waitUntil { options.productDiscovery.state == .configured }
        let selectedRoot = try #require(package.packageURL)
        #expect(options.preparedPackage(in: selectedRoot)?.environment.swiftVersion == fixture.older)
        #expect(!package.isConfigurationReady)
        hosting.rootView = AnyView(EmptyView())
    }

    @Test("Configuration supplies selectable root products without starting a build or graph workflow")
    func configurationIsIndependentOfBuild() async throws {

        let fixture = try StagedPackageFixture()
        defer { fixture.remove() }
        let options = BuildOptions(discoveryOperations: fixture.discoveryOperations())
        await options.discoverPackage(in: fixture.root, for: .linux(.x86_64), toolchain: .exact(fixture.older))

        #expect(options.productDiscovery.state == .configured)
        #expect(options.productDiscovery.availableProducts.map(\.name) == ["Tool"])
        #expect(options.preparedPackage(in: fixture.root)?.environment.swiftVersion == fixture.older)
        #expect(options.toolchain == .exact(fixture.older))
        #expect(options.buildWorkflow.state == .idle)
    }

    @Test("A superseded package cannot publish delayed toolchain results")
    func supersededToolchains() async throws {

        let fixture = try StagedPackageFixture()
        defer { fixture.remove() }
        let gate = WorkflowGate()
        let oldChoices = fixture.choices()
        let currentChoices = fixture.choices(in: fixture.otherRoot)
        let oldRoot = fixture.root
        var operations = fixture.discoveryOperations()
        operations.compatibleEnvironments = { root, _ in
            if root == oldRoot {
                await gate.wait()
                return oldChoices
            }
            return currentChoices
        }
        let options = BuildOptions(discoveryOperations: operations)
        let obsolete = Task {
            await options.discoverPackage(in: fixture.root, for: .linux(.x86_64), toolchain: .automatic)
        }
        await gate.waitForEntry()
        await options.discoverPackage(in: fixture.otherRoot, for: .linux(.x86_64), toolchain: .automatic)
        await gate.open()
        await obsolete.value

        #expect(options.preparedPackage(in: fixture.root) == nil)
        #expect(options.preparedPackage(in: fixture.otherRoot) != nil)
        #expect(options.hasDiscoveredToolchains(in: fixture.otherRoot, for: .linux(.x86_64)))
        #expect(!options.hasDiscoveredToolchains(in: fixture.root, for: .linux(.x86_64)))
    }

    @Test("Delayed progress and errors from an obsolete configuration cannot overwrite its replacement")
    func supersededConfigurationEvents() async throws {

        let fixture = try StagedPackageFixture()
        defer { fixture.remove() }
        let oldGate = WorkflowGate()
        let currentGate = WorkflowGate()
        let oldRoot = fixture.root.resolvingSymlinksInPath().standardizedFileURL
        var operations = fixture.discoveryOperations()
        operations.configure = { environment, onEvent in
            if environment.packageRoot == oldRoot {
                await oldGate.wait()
                await onEvent?(.progress(OperationProgress(operation: .inspectingPackage, detail: "Obsolete progress")))
                throw SwiftlyKitError.packageInspectionFailed("Obsolete failure")
            }
            await onEvent?(.progress(OperationProgress(operation: .inspectingPackage, detail: "Current products")))
            await currentGate.wait()
            return PackageConfiguration(
                environment: environment,
                products: ExecutableProducts([ExecutableProduct(name: "Current")])
            )
        }
        let options = BuildOptions(discoveryOperations: operations)
        let obsolete = Task {
            await options.discoverPackage(in: fixture.root, for: .linux(.x86_64), toolchain: .automatic)
        }
        await oldGate.waitForEntry()
        let current = Task {
            await options.discoverPackage(in: fixture.otherRoot, for: .linux(.x86_64), toolchain: .automatic)
        }
        await currentGate.waitForEntry()
        await oldGate.open()
        await obsolete.value
        #expect(options.productDiscovery.state == .discovering(detail: "Current products"))
        await currentGate.open()
        await current.value

        #expect(options.productDiscovery.state == .configured)
        #expect(options.productDiscovery.availableProducts.map(\.name) == ["Current"])
    }

    @Test("A cleared host check cannot restore readiness from its delayed result")
    func clearedHostCheck() async {

        let gate = WorkflowGate()
        let host = HostDiscovery(readiness: {
            await gate.wait()
            return .ready
        })
        let obsolete = Task { await host.inspect() }
        await gate.waitForEntry()
        host.clear()
        await gate.open()
        await obsolete.value
        #expect(host.state == .idle)
    }

    @Test("Build starts with visible dependency validation and ignores events after cancellation")
    func cancellableValidation() async throws {

        let fixture = try StagedPackageFixture()
        defer { fixture.remove() }
        let gate = WorkflowGate()
        var operations = fixture.buildOperations()
        operations.build = { _, _, onEvent in
            await gate.wait()
            await onEvent?(.progress(OperationProgress(operation: .building, detail: "Late compiler progress")))
            return fixture.result
        }
        let workflow = BuildWorkflow(operations: operations)
        workflow.start(fixture.prepared(), target: .linux(.x86_64), configuration: .release, stripBinary: false)
        #expect(workflow.state == .active(phase: .inspectingPackage, detail: "Validating dependencies before compilation."))
        await gate.waitForEntry()
        workflow.cancel()
        await gate.open()
        await waitUntil { !workflow.isRunning }

        #expect(workflow.state == .cancelled)
        #expect(workflow.result == nil)
        #expect(!workflow.log.text.contains("Late compiler progress"))
    }

    @Test("Automatic graph failure can use a newer installed pair; exact selections and package pins remain fixed")
    func automaticBuildRecovery() async throws {

        let fixture = try StagedPackageFixture()
        defer { fixture.remove() }
        let older = fixture.older
        let versions = VersionRecorder()
        var operations = fixture.buildOperations()
        operations.build = { _, environment, _ in
            await versions.record(environment.swiftVersion)
            if environment.swiftVersion == older {
                throw SwiftlyKitError.hostCompilationFailed(swiftVersion: older, detail: "No installed host SDK succeeded")
            }
            return fixture.result
        }
        let workflow = BuildWorkflow(operations: operations)
        workflow.start(
            fixture.prepared(),
            target: .linux(.x86_64),
            configuration: .release,
            stripBinary: false,
            environmentChoices: fixture.choices(),
            toolchain: .automatic
        )
        await waitUntil { !workflow.isRunning }
        #expect(workflow.state == .succeeded)
        #expect(await versions.values == [fixture.older, fixture.newer])
        #expect(workflow.identity?.swiftVersion == fixture.newer)

        let exact = BuildWorkflow(operations: operations)
        exact.start(
            fixture.prepared(),
            target: .linux(.x86_64),
            configuration: .release,
            stripBinary: false,
            environmentChoices: fixture.choices(),
            toolchain: .exact(fixture.older)
        )
        await waitUntil { !exact.isRunning }
        guard case .failed = exact.state else {
            Issue.record("Exact Swift selection must report the host failure rather than switch compilers")
            return
        }
        #expect(await versions.values == [fixture.older, fixture.newer, fixture.older])

        try Data("6.3.3\n".utf8).write(to: fixture.root.appending(path: ".swift-version"))
        let pinned = BuildWorkflow(operations: operations)
        pinned.start(
            fixture.prepared(),
            target: .linux(.x86_64),
            configuration: .release,
            stripBinary: false,
            environmentChoices: fixture.choices(),
            toolchain: .automatic
        )
        await waitUntil { !pinned.isRunning }
        guard case .failed = pinned.state else {
            Issue.record("A package pin must prevent automatic compiler recovery")
            return
        }
        #expect(await versions.values == [fixture.older, fixture.newer, fixture.older, fixture.older])
    }

    @Test("A missing recovery compiler requires approval before preparation and resumes the captured build")
    func approvedBuildRecovery() async throws {

        let fixture = try StagedPackageFixture()
        defer { fixture.remove() }
        let older = fixture.older
        let preparedVersions = VersionRecorder()
        var operations = fixture.buildOperations()
        operations.prepare = { assessment, _ in
            await preparedVersions.record(assessment.swiftVersion)
            return fixture.environment(in: assessment.packageRoot, version: assessment.swiftVersion)
        }
        operations.build = { _, environment, _ in
            if environment.swiftVersion == older {
                throw SwiftlyKitError.hostCompilationFailed(swiftVersion: older, detail: "No installed host SDK succeeded")
            }
            return fixture.result
        }
        let workflow = BuildWorkflow(operations: operations)
        workflow.start(
            fixture.prepared(),
            target: .linux(.x86_64),
            configuration: .debug,
            stripBinary: true,
            environmentChoices: fixture.choices(newerRequiresInstallation: true)
        )
        await waitUntil {
            if case .installationRequired = workflow.state { return true }
            return false
        }
        #expect(await preparedVersions.values.isEmpty)
        #expect(workflow.installationApprovalRevision == 1)
        workflow.approveInstallation()
        await waitUntil { !workflow.isRunning }

        #expect(workflow.state == .succeeded)
        #expect(await preparedVersions.values == [fixture.newer])
        #expect(workflow.identity?.configuration == .debug)
        #expect(workflow.identity?.stripBinary == true)

        let cancelled = BuildWorkflow(operations: operations)
        cancelled.start(
            fixture.prepared(),
            target: .linux(.x86_64),
            configuration: .release,
            stripBinary: false,
            environmentChoices: fixture.choices(newerRequiresInstallation: true)
        )
        await waitUntil {
            if case .installationRequired = cancelled.state { return true }
            return false
        }
        cancelled.cancel()
        cancelled.approveInstallation()
        #expect(cancelled.state == .cancelled)
        #expect(await preparedVersions.values == [fixture.newer])
    }

    @Test("Recovery preparation failure ends the captured build", arguments: [false, true])
    func recoveryPreparationFailure(requiresApproval: Bool) async throws {

        let fixture = try StagedPackageFixture()
        defer { fixture.remove() }
        let builds = VersionRecorder()
        let failure = SwiftlyKitError.swiftlyInstallationFailed("Recovery preparation failed")
        var operations = fixture.buildOperations()
        operations.build = { _, environment, _ in
            await builds.record(environment.swiftVersion)
            throw SwiftlyKitError.hostCompilationFailed(swiftVersion: fixture.older, detail: "Host compiler failed")
        }
        operations.prepare = { _, _ in throw failure }
        let workflow = BuildWorkflow(operations: operations)
        workflow.start(
            fixture.prepared(),
            target: .linux(.x86_64),
            configuration: .debug,
            stripBinary: true,
            environmentChoices: fixture.choices(newerRequiresInstallation: requiresApproval)
        )
        if requiresApproval {
            await waitUntil {
                if case .installationRequired = workflow.state { return true }
                return false
            }
            workflow.approveInstallation()
        }
        await waitUntil { !workflow.isRunning }

        #expect(workflow.state == .failed(failure.localizedDescription))
        #expect(workflow.result == nil)
        #expect(workflow.identity == nil)
        #expect(await builds.values == [fixture.older])
    }

    @Test("Cancellation during recovery preparation rejects its environment and late events", arguments: [false, true])
    func cancelledRecoveryPreparation(requiresApproval: Bool) async throws {

        let fixture = try StagedPackageFixture()
        defer { fixture.remove() }
        let gate = WorkflowGate()
        let builds = VersionRecorder()
        var operations = fixture.buildOperations()
        operations.build = { _, environment, _ in
            await builds.record(environment.swiftVersion)
            throw SwiftlyKitError.hostCompilationFailed(swiftVersion: fixture.older, detail: "Host compiler failed")
        }
        operations.prepare = { assessment, onEvent in
            await gate.wait()
            await onEvent?(.progress(OperationProgress(operation: .building, detail: "Late recovery progress")))
            return fixture.environment(version: assessment.swiftVersion)
        }
        let workflow = BuildWorkflow(operations: operations)
        workflow.start(
            fixture.prepared(),
            target: .linux(.x86_64),
            configuration: .debug,
            stripBinary: true,
            environmentChoices: fixture.choices(newerRequiresInstallation: requiresApproval)
        )
        if requiresApproval {
            await waitUntil {
                if case .installationRequired = workflow.state { return true }
                return false
            }
            workflow.approveInstallation()
        }
        await gate.waitForEntry()
        #expect(workflow.identity?.swiftVersion == fixture.older)
        workflow.cancel()
        await gate.open()
        await waitUntil { !workflow.isRunning }

        #expect(workflow.state == .cancelled)
        #expect(workflow.result == nil)
        #expect(workflow.identity == nil)
        #expect(await builds.values == [fixture.older])
        #expect(!workflow.log.text.contains("Late recovery progress"))
    }

}

@MainActor
private func waitUntil(_ predicate: @escaping @MainActor () -> Bool) async {

    while !predicate() {
        await withCheckedContinuation { continuation in
            withObservationTracking {
                _ = predicate()
            } onChange: {
                continuation.resume()
            }
        }
    }
}

private actor WorkflowGate {

    private var entered = false
    private var isOpen = false
    private var waiting: CheckedContinuation<Void, Never>?
    private var entryWaiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {

        entered = true
        entryWaiters.forEach { $0.resume() }
        entryWaiters.removeAll()
        if isOpen { return }
        await withCheckedContinuation { waiting = $0 }
    }

    func waitForEntry() async {
        if entered { return }
        await withCheckedContinuation { entryWaiters.append($0) }
    }

    func open() {
        isOpen = true
        waiting?.resume()
        waiting = nil
    }

}

private actor VersionRecorder {

    private(set) var values: [SwiftVersion] = []

    func record(_ value: SwiftVersion) { values.append(value) }

}

private actor DiscoveryCallRecorder {

    private(set) var count = 0

    func record() { count += 1 }

}

private nonisolated struct StagedPackageFixture: Sendable {

    let root: URL
    let otherRoot: URL
    let older = SwiftVersion(major: 6, minor: 3, patch: 3)
    let newer = SwiftVersion(major: 6, minor: 4, patch: 0)

    init() throws {

        root = FileManager.default.temporaryDirectory.appending(path: "StagedApp-" + UUID().uuidString)
        otherRoot = root.appending(path: "OtherPackage")
        for directory in [root, otherRoot] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data("// swift-tools-version: 6.0\n".utf8).write(to: directory.appending(path: "Package.swift"))
        }
    }

    func remove() { try? FileManager.default.removeItem(at: root) }

    var result: BuildResult {
        BuildResult(
            executable: root.appending(path: "Tool"),
            executableName: "Tool",
            resourceBundles: [],
            architecture: .x86_64
        )
    }

    func environment(in packageRoot: URL? = nil, version: SwiftVersion? = nil) -> LocalBuildEnvironment {
        LocalBuildEnvironment(
            swiftVersion: version ?? older,
            staticLinuxSDK: StaticLinuxSDK(identifier: "test", version: "0.1.0"),
            packageRoot: packageRoot ?? root,
            swiftly: SwiftlyInstallation(executableURL: URL(filePath: "/fixture/swiftly")),
            sdkBundleURL: root.appending(path: "sdk.artifactbundle"),
            target: .linux(.x86_64),
            swiftPMEnvironment: SwiftPMEnvironment.inherited.snapshot(inheriting: [:])
        )
    }

    @MainActor
    func prepared() -> PreparedPackage {
        PreparedPackage(environment: environment(), selectedProduct: ExecutableProduct(name: "Tool"))
    }

    func choices(in packageRoot: URL? = nil, newerRequiresInstallation: Bool = false) -> EnvironmentChoices {

        let inputs = try! PackageInputSnapshot.capture(at: packageRoot ?? root)
        let releases = [newer, older].map { version in
            OfficialStableRelease(
                version: version,
                staticLinuxSDK: StaticLinuxSDK(identifier: "test-\(version)", version: "0.1.0"),
                staticLinuxSDKMetadata: StaticLinuxSDKMetadata(
                    downloadURL: URL(string: "https://download.swift.org/fixture.tar.gz")!,
                    checksum: String(repeating: "a", count: 64),
                    supportedArchitectures: [.x86_64]
                )!
            )
        }
        let assessments = releases.map {
            EnvironmentAssessment(
                packageInputs: inputs,
                release: $0,
                requiredComponents: newerRequiresInstallation && $0.version == newer ? [.toolchain, .staticLinuxSDK] : [],
                target: .linux(.x86_64)
            )
        }
        let installed = newerRequiresInstallation ? [older] : [older, newer]
        return EnvironmentChoices(
            assessments: assessments,
            toolsVersion: inputs.toolsVersion,
            swiftVersionPreference: inputs.swiftVersion,
            architecture: .x86_64,
            releases: releases,
            inventory: InstalledEnvironmentInventory(
                toolchains: installed,
                sdks: installed.map { InstalledStaticLinuxSDK(toolchainVersion: $0, identifier: "test-\($0)") }
            ),
            usesCachedCatalog: false
        )
    }

    func discoveryOperations() -> PackageDiscoveryOperations {

        var operations = PackageDiscoveryOperations(swiftlyKit: SwiftlyKit())
        operations.hostReadiness = { .ready }
        operations.compatibleEnvironments = { packageRoot, _ in choices(in: packageRoot) }
        operations.prepare = { assessment, _ in environment(in: assessment.packageRoot, version: assessment.swiftVersion) }
        operations.configure = { environment, _ in
            PackageConfiguration(environment: environment, products: ExecutableProducts([ExecutableProduct(name: "Tool")]))
        }
        return operations
    }

    func buildOperations() -> BuildWorkflowOperations {

        var operations = BuildWorkflowOperations(swiftlyKit: SwiftlyKit())
        operations.build = { _, _, _ in result }
        operations.prepare = { assessment, _ in environment(in: assessment.packageRoot, version: assessment.swiftVersion) }
        return operations
    }

}
