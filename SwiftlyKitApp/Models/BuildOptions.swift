import Observation
import SwiftlyKit

@MainActor
@Observable
final class BuildOptions {
    
    var target: BuildTarget = .linux(.x86_64)
    var configuration: BuildConfiguration = .release
    var selectedProductName = ""
    var toolchain: ToolchainSelection = .automatic
    var stripBinary = false
    
}

extension BuildTarget {
    var displayName: String {
        switch self {
            case .linux(.x86_64): "x86_64 Linux"
            case .linux(.arm64): "ARM64 Linux"
        }
    }

}

extension BuildConfiguration {
    var displayName: String {
        switch self {
            case .debug: "Debug"
            case .release: "Release"
        }
    }

}

extension ToolchainSelection {

    var displayName: String {
        switch self {
            case .automatic: "Automatic"
            case .exact(let version): "Swift \(version.description)"
        }
    }

}
