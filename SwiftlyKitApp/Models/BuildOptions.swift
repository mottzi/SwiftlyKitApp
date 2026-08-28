import Foundation
import Observation
import SwiftlyKit

/// Current state of executable-product discovery for the selected package and environment.
enum ProductDiscoveryState: Equatable {

    /// No package environment is being inspected.
    case idle

    /// SwiftlyKit is preparing an environment and inspecting the package.
    case discovering

    /// Executable products were discovered in name order.
    case ready([ExecutableProduct])

    /// Package inspection succeeded without finding an executable product.
    case empty

    /// SwiftlyKit could not complete product discovery.
    case failed(SwiftlyKitError)

}

/// Build choices shared by the package configuration controls.
@Observable final class BuildOptions {

    /// Current executable-product discovery state.
    private(set) var productDiscoveryState: ProductDiscoveryState = .idle

    /// Executable products available for selection.
    var availableProducts: [ExecutableProduct] {
        guard case .ready(let products) = productDiscoveryState else { return [] }
        return products
    }

    /// Selected executable package product.
    var selectedProduct: ExecutableProduct?

    /// Selected cross-compilation target.
    var target: BuildTarget = .linux(.x86_64)

    /// Selected SwiftPM build configuration.
    var configuration: BuildConfiguration = .release

    /// Selected Swift toolchain policy.
    var toolchain: ToolchainSelection = .automatic

    /// Whether the strip-binary toggle is enabled.
    var stripBinary = false

    /// Whether every required build choice has a valid selection.
    var hasValidSelections: Bool {
        selectedProduct != nil
    }

    private let swiftlyKit: SwiftlyKit

    init(swiftlyKit: SwiftlyKit = SwiftlyKit()) {
        self.swiftlyKit = swiftlyKit
    }

    /// Prepares a compatible environment and discovers products for the current build choices.
    func discoverProducts(
        in packageRoot: URL,
        for target: BuildTarget,
        toolchain: ToolchainSelection
    ) async {

        selectedProduct = nil
        productDiscoveryState = .discovering

        do {
            let assessment = try await swiftlyKit.assess(
                packageRoot,
                for: target,
                toolchain: toolchain
            )
            let environment = try await swiftlyKit.prepare(assessment)
            let products = try await swiftlyKit.executableProducts(using: environment)

            guard !Task.isCancelled else { return }

            let discoveredProducts = Array(products)
            productDiscoveryState = discoveredProducts.isEmpty
                ? .empty
                : .ready(discoveredProducts)
        } catch is CancellationError {
            // A replacement task owns the next state transition.
        } catch let error as SwiftlyKitError {
            guard !Task.isCancelled else { return }
            productDiscoveryState = .failed(error)
        } catch {
            guard !Task.isCancelled else { return }
            productDiscoveryState = .failed(
                .packageInspectionFailed("An unexpected product discovery error occurred.")
            )
        }
    }

    /// Clears products that belong to a package or environment that is no longer selected.
    func clearProducts() {
        productDiscoveryState = .idle
        selectedProduct = nil
    }

}

extension BuildTarget {

    /// User-facing label for the target picker.
    var displayName: String {
        switch self {
            case .linux(.x86_64): "x86_64 Linux"
            case .linux(.arm64): "ARM64 Linux"
        }
    }

}

extension BuildConfiguration {

    /// User-facing label for the configuration picker.
    var displayName: String {
        switch self {
            case .debug: "Debug"
            case .release: "Release"
        }
    }

}

extension ToolchainSelection {

    /// User-facing label for this toolchain selection.
    var displayName: String {
        switch self {
            case .automatic: "Automatic"
            case .exact(let version): "Swift \(version.description)"
        }
    }

}
