import AppKit
import SwiftUI
import Testing
@testable import TripleApp

@Suite(.serialized)
struct PackageSectionAnimationTests {

    @MainActor
    @Test(arguments: [360.0, 440.0, 800.0], [false, true])
    func appWindowStartupDoesNotAnimateLayout(width: CGFloat, appearsActive: Bool) async throws {
        let capture = PackageSectionAnimationCapture()
        let hostingView = NSHostingView(rootView: appRootView(capture: capture, appearsActive: false))
        // WindowGroup can size its host before applying the restored window dimensions.
        hostingView.frame = CGRect(x: 0, y: 0, width: 500, height: 420)
        for _ in 0..<10 {
            hostingView.layoutSubtreeIfNeeded()
            await Task.yield()
        }
        capture.animatedUpdates = 0
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: width, height: 600),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.toolbar = NSToolbar(identifier: "PackageLaunchAnimationTests")
        window.toolbarStyle = .unifiedCompact
        window.contentView = hostingView
        // A standalone NSHostingView has no WindowGroup to supply its per-window environment.
        hostingView.rootView = appRootView(capture: capture, appearsActive: appearsActive)
        window.makeKeyAndOrderFront(nil)
        defer { window.close() }

        let first = try snapshot(hostingView)
        try await Task.sleep(for: .milliseconds(80))
        let early = try snapshot(hostingView)
        try await Task.sleep(for: .milliseconds(500))
        let settled = try snapshot(hostingView)

        #expect(capture.animatedUpdates == 0)
        #expect(first == early, "The first visible app layout moved at width \(width).")
        #expect(early == settled, "The app layout kept moving at width \(width).")

        if width == 800 && appearsActive {
            capture.animatedUpdates = 0
            window.setContentSize(CGSize(width: 360, height: 600))
            try await Task.sleep(for: .milliseconds(80))
            let resizing = try snapshot(hostingView)
            try await Task.sleep(for: .milliseconds(500))
            let resized = try snapshot(hostingView)
            #expect(capture.animatedUpdates > 0)
            #expect(resizing != resized, "The first resize after restoring a wide window should animate.")
        }
    }

    @MainActor
    @Test(arguments: [360.0, 500.0, 800.0])
    func startupDoesNotAnimateLayout(width: CGFloat) async throws {
        let capture = PackageSectionAnimationCapture()
        let hostingView = NSHostingView(rootView: rootView(capture: capture))
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: width, height: 400),
            styleMask: [.titled, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        defer { window.close() }

        for _ in 0..<10 {
            hostingView.layoutSubtreeIfNeeded()
            await Task.yield()
        }
        try await Task.sleep(for: .milliseconds(80))
        let early = try snapshot(hostingView)
        try await Task.sleep(for: .milliseconds(500))
        let settled = try snapshot(hostingView)

        #expect(capture.animatedUpdates == 0, "Startup height events: \(capture.heights)")
        #expect(early == settled, "The package section moved after its initial layout at width \(width).")
    }

    @MainActor
    @Test
    func resizingStillAnimatesAndRestoresLayout() async throws {
        let capture = PackageSectionAnimationCapture()
        let hostingView = NSHostingView(rootView: rootView(capture: capture))
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 800, height: 400),
            styleMask: [.titled, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        defer { window.close() }
        try await Task.sleep(for: .milliseconds(600))
        let wide = try snapshot(hostingView)
        let wideHeight = try #require(capture.heights.last)
        capture.animatedUpdates = 0

        window.setContentSize(CGSize(width: 360, height: 400))
        try await Task.sleep(for: .milliseconds(80))
        let intermediate = try snapshot(hostingView)
        try await Task.sleep(for: .milliseconds(500))
        let narrow = try snapshot(hostingView)
        let narrowHeight = try #require(capture.heights.last)

        #expect(capture.animatedUpdates > 0)
        #expect(intermediate != narrow, "Resizing should still animate the section and picker.")
        #expect(narrowHeight > wideHeight + 40)

        capture.animatedUpdates = 0
        window.setContentSize(CGSize(width: 800, height: 400))
        try await Task.sleep(for: .milliseconds(600))
        let restored = try snapshot(hostingView)
        #expect(capture.animatedUpdates > 0)
        #expect(abs(try #require(capture.heights.last) - wideHeight) < 0.5)
        #expect(wide == restored)
    }

    @MainActor
    @Test
    func packageSelectionStillAnimates() async throws {
        let capture = PackageSectionAnimationCapture()
        let hostingView = NSHostingView(rootView: rootView(capture: capture))
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        defer { window.close() }
        try await Task.sleep(for: .milliseconds(600))
        let picker = try snapshot(hostingView)
        capture.animatedUpdates = 0

        let packageURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: packageURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: packageURL) }
        try Data().write(to: packageURL.appendingPathComponent("Package.swift"))

        withAnimation(.default, completionCriteria: .removed) {
            capture.packageModel.selectPackage(at: packageURL)
        } completion: {
            capture.packageModel.finishConfigurationTransition()
        }
        try await Task.sleep(for: .milliseconds(80))
        let intermediate = try snapshot(hostingView)
        try await Task.sleep(for: .milliseconds(700))
        let configuration = try snapshot(hostingView)

        #expect(capture.animatedUpdates > 0)
        #expect(intermediate != configuration)
        #expect(configuration != picker)
        for _ in 0..<100 where !capture.packageModel.isConfigurationReady {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(capture.packageModel.isConfigurationReady)
    }

    @MainActor
    private func appRootView(capture: PackageSectionAnimationCapture, appearsActive: Bool) -> some View {
        AppView()
            .environment(\.appearsActive, appearsActive)
            .transaction {
                if $0.animation != nil && !$0.disablesAnimations {
                    capture.animatedUpdates += 1
                }
            }
    }

    @MainActor
    private func rootView(capture: PackageSectionAnimationCapture) -> some View {
        VStack(spacing: 0) {
            PackageSection()
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                    capture.heights.append($0)
                }
                .transaction {
                    if $0.animation != nil && !$0.disablesAnimations {
                        capture.animatedUpdates += 1
                    }
                }
            Spacer(minLength: 0)
        }
        .clipped()
        .environment(capture.packageModel)
        .environment(BuildOptions())
        .environment(\.appearsActive, true)
    }

    @MainActor
    private func snapshot(_ hostingView: NSView) throws -> Data {
        hostingView.layoutSubtreeIfNeeded()
        hostingView.displayIfNeeded()
        let bitmap = try #require(hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds))
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
        return try #require(bitmap.representation(using: .png, properties: [:]))
    }
}

@MainActor
private final class PackageSectionAnimationCapture {
    let packageModel = PackageModel()
    var heights: [CGFloat] = []
    var animatedUpdates = 0
}
