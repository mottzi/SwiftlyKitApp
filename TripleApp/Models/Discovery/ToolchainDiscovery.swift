import Foundation
import Observation
import Triple

/// Current state of compatible Swift toolchain discovery for the selected package and target.
enum ToolchainDiscoveryState: Equatable {

    /// No package and target are being inspected.
    case idle

    /// Triple is inspecting the package and official release catalog.
    case discovering

    /// Compatible exact toolchain selections were discovered in newest-first order.
    case ready([ToolchainSelection])

    /// No official stable release supports the selected package and target.
    case empty

    /// Triple could not complete toolchain discovery.
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
    @ObservationIgnored private var discoveryID = UUID()
    private let compatibleEnvironments: @Sendable (URL, BuildTarget) async throws -> EnvironmentChoices

    init(triple: Triple) {
        compatibleEnvironments = { try await triple.compatibleEnvironments($0, for: $1) }
    }

    init(compatibleEnvironments: @escaping @Sendable (URL, BuildTarget) async throws -> EnvironmentChoices) {
        self.compatibleEnvironments = compatibleEnvironments
    }

    /// Discovers exact compatible Swift releases without mutating the local environment.
    func discover(
        in packageRoot: URL,
        for target: BuildTarget,
        selectedToolchain: ToolchainSelection
    ) async -> ToolchainSelection? {
        let discoveryID = UUID()
        self.discoveryID = discoveryID
        choices = nil
        context = nil
        state = .discovering

        do {
            let choices = try await compatibleEnvironments(packageRoot, target)

            guard isCurrent(discoveryID) else { return nil }

            let toolchains = choices.map { ToolchainSelection.exact($0.swiftVersion) }
            guard !toolchains.isEmpty else {
                state = .empty
                return .automatic
            }

            self.choices = choices
            context = Context(packageRoot: packageRoot, target: target)
            revision += 1
            state = .ready(toolchains)

            return Self.reconciledToolchain(
                selectedToolchain,
                available: toolchains,
                usesCachedCatalog: choices.usesCachedCatalog
            )
        } catch is CancellationError {
            // a replacement task owns the next state transition
            return nil
        } catch let error as TripleError {
            guard isCurrent(discoveryID) else { return nil }

            state = .failed(error.errorDescription ?? error.localizedDescription)
            return nil
        } catch {
            guard isCurrent(discoveryID) else { return nil }

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
        discoveryID = UUID()
        state = .idle
        choices = nil
        context = nil
    }

}

extension ToolchainDiscovery {

    private func isCurrent(_ discoveryID: UUID) -> Bool {
        self.discoveryID == discoveryID && !Task.isCancelled
    }

    /// Preserves exact selections if an outage limits discovery to installed environments.
    static func reconciledToolchain(
        _ current: ToolchainSelection,
        available: [ToolchainSelection],
        usesCachedCatalog: Bool = false
    ) -> ToolchainSelection {
        if usesCachedCatalog || available.contains(current) { return current }
        return .automatic
    }

}

extension ToolchainDiscovery {

    /// Package and target associated with the retained environment choices.
    private struct Context: Equatable {
        let packageRoot: URL
        let target: BuildTarget
    }

}
