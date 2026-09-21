import Foundation
import Observation
import SwiftlyKit

/// Current state of compatible Swift toolchain discovery for the selected package and target.
enum ToolchainDiscoveryState: Equatable {

    /// No package and target are being inspected.
    case idle

    /// SwiftlyKit is inspecting the package and official release catalog.
    case discovering

    /// Compatible exact toolchain selections were discovered in newest-first order.
    case ready([ToolchainSelection])

    /// No official stable release supports the selected package and target.
    case empty

    /// SwiftlyKit could not complete toolchain discovery.
    case failed(String)

}

@Observable
/// Discovers compatible toolchains and retains the matching environment assessments.
final class ToolchainDiscovery {

    /// Current compatible-toolchain discovery state.
    private(set) var state: ToolchainDiscoveryState = .idle

    /// Revision that requests another app-level discovery task.
    private(set) var retryRevision = 0

    /// Revision identifying the current successful discovery result.
    private(set) var revision = 0

    @ObservationIgnored private var choices: EnvironmentChoices?
    @ObservationIgnored private var context: Context?
    private let swiftlyKit: SwiftlyKit

    init(swiftlyKit: SwiftlyKit) {
        self.swiftlyKit = swiftlyKit
    }

    /// Discovers exact compatible Swift releases without mutating the local environment.
    func discover(
        in packageRoot: URL,
        for target: BuildTarget,
        selectedToolchain: ToolchainSelection
    ) async -> ToolchainSelection? {
        choices = nil
        context = nil
        state = .discovering

        do {
            let choices = try await swiftlyKit.compatibleEnvironments(packageRoot, for: target)

            guard !Task.isCancelled else { return nil }

            let toolchains = choices.map { ToolchainSelection.exact($0.swiftVersion) }
            guard !toolchains.isEmpty else {
                state = .empty
                return .automatic
            }

            self.choices = choices
            context = Context(packageRoot: packageRoot, target: target)
            revision += 1
            state = .ready(toolchains)

            return Self.reconciledToolchain(selectedToolchain, available: toolchains)
        } catch is CancellationError {
            // a replacement task owns the next state transition
            return nil
        } catch let error as SwiftlyKitError {
            guard !Task.isCancelled else { return nil }

            state = .failed(error.errorDescription ?? error.localizedDescription)
            return nil
        } catch {
            guard !Task.isCancelled else { return nil }

            state = .failed("An unexpected toolchain discovery error occurred.")
            return nil
        }
    }

    /// Exact compatible Swift toolchains available for selection.
    var availableToolchains: [ToolchainSelection] {
        guard case .ready(let toolchains) = state else { return [] }
        return toolchains
    }

    /// Whether successful discovery belongs to the supplied package and target.
    func hasResults(in packageRoot: URL, for target: BuildTarget) -> Bool {
        guard case .ready = state else { return false }
        return context == Context(packageRoot: packageRoot, target: target)
    }

    /// Returns cached environment assessments for the supplied package and target.
    func environmentChoices(in packageRoot: URL, for target: BuildTarget) -> EnvironmentChoices? {
        guard context == Context(packageRoot: packageRoot, target: target) else { return nil }
        return choices
    }

    /// Requests another discovery through the existing app-level task.
    func requestRetry() {
        retryRevision += 1
    }

    /// Clears results that belong to a package or target that is no longer selected.
    func clear() {
        state = .idle
        choices = nil
        context = nil
    }

}

extension ToolchainDiscovery {

    /// Keeps an exact selection only while it remains compatible.
    static func reconciledToolchain(_ current: ToolchainSelection, available: [ToolchainSelection]) -> ToolchainSelection {

        if current == .automatic || !available.contains(current) {
            .automatic
        } else {
            current
        }
    }

}

extension ToolchainDiscovery {

    private struct Context: Equatable {
        let packageRoot: URL
        let target: BuildTarget
    }

}
