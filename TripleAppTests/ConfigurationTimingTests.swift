import AppKit
import Foundation
import Triple
import SwiftUI
import Testing
@testable import TripleApp

@MainActor
struct ConfigurationTimingTests {

    @Test(
        "Measure package selection through usable configuration in the hosted SwiftUI workflow",
        .enabled(
            if: ProcessInfo.processInfo.environment["TRIPLE_CONFIGURATION_BENCHMARK"] != nil,
            "Run script/benchmark_deployer_setup.sh to measure configuration."
        )
    )
    func selectionTiming() async throws {

        let variables = ProcessInfo.processInfo.environment
        let root = URL(filePath: try #require(variables["TRIPLE_DEPLOYER_PACKAGE"]))
        let destination = URL(filePath: try #require(variables["TRIPLE_CONFIGURATION_TIMINGS"]))
        let limit = variables["TRIPLE_CONFIGURATION_MAX_SECONDS"].flatMap(Double.init)
        let selections: [ToolchainSelection] = [.automatic, .exact(SwiftVersion(major: 6, minor: 3, patch: 3))]
        let clock = ContinuousClock()
        var records: [String] = []
        for selection in selections {
            for iteration in 1...3 {
                let package = PackageModel()
                let options = BuildOptions()
                let hosting = NSHostingView(rootView: AnyView(
                    VStack {
                        PackageSection()
                        BuildSection()
                    }
                    .environment(package)
                    .environment(options)
                    .managesPackageDiscovery(packageModel: package, buildOptions: options)
                ))
                hosting.frame = CGRect(x: 0, y: 0, width: 500, height: 420)
                let window = NSWindow(
                    contentRect: hosting.frame,
                    styleMask: [.titled, .resizable],
                    backing: .buffered,
                    defer: false
                )
                window.isReleasedWhenClosed = false
                window.contentView = hosting
                window.makeKeyAndOrderFront(nil)
                defer { window.close() }
                hosting.layoutSubtreeIfNeeded()
                try await Task.sleep(for: .milliseconds(10))
                options.toolchain = selection
                let start = clock.now
                withAnimation(.default, completionCriteria: .removed) {
                    package.selectPackage(at: root)
                } completion: {
                    package.finishConfigurationTransition()
                }
                let deadline = start + .seconds(60)
                while (!package.isConfigurationReady || options.preparedPackage(in: root) == nil), clock.now < deadline {
                    try await Task.sleep(for: .milliseconds(10))
                }
                let elapsed = Self.seconds(start.duration(to: clock.now))
                let prepared = try #require(options.preparedPackage(in: root),
                    "Configuration failed: \(options.productDiscovery.state)")
                #expect(prepared.selectedProduct.name == "deployer")
                if case .exact(let version) = selection { #expect(prepared.environment.swiftVersion == version) }
                records.append("TRIPLE_CONFIGURATION_TIMING selection=\(selection) run=\(iteration) "
                    + "swift=\(prepared.environment.swiftVersion) sdk=\(prepared.environment.hostSDKVersion ?? "unknown") "
                    + "total=\(elapsed)")
                try Data((records.joined(separator: "\n") + "\n").utf8).write(to: destination)
                hosting.rootView = AnyView(EmptyView())
                await Task.yield()
                if let limit { #expect(elapsed <= limit, "Every configuration run must meet the limit: \(elapsed)s") }
            }
        }
    }

    private static func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }

}
