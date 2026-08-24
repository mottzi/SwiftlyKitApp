import Observation
import SwiftlyKit

/// Build choices shared by the package configuration controls.
@Observable
final class BuildOptions {

    /// Name of the selected package product.
    var selectedProductName = ""

    /// Selected cross-compilation target.
    var target: BuildTarget = .linux(.x86_64)

    /// Selected SwiftPM build configuration.
    var configuration: BuildConfiguration = .release

    /// Selected Swift toolchain policy.
    var toolchain: ToolchainSelection = .automatic

    /// Whether the strip-binary toggle is enabled.
    var stripBinary = false

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
