import Observation
import SwiftlyKit

@MainActor
@Observable
final class BuildOptions {
    
    var linuxTarget: LinuxTarget = .x86_64
    var buildStyle: BuildStyle = .release
    var selectedProductName = ""
    var toolchainOption: ToolchainOption = .automatic
    var stripBinary = false
    
}

enum LinuxTarget: String, CaseIterable, Identifiable {

    case x86_64
    case arm64

    var id: Self { self }

    var displayName: String {
        switch self {
            case .x86_64: "x86_64 Linux"
            case .arm64: "ARM64 Linux"
        }
    }

    var swiftly: LinuxArchitecture {
        switch self {
            case .x86_64: .x86_64
            case .arm64: .arm64
        }
    }
    
}

enum BuildStyle: String, CaseIterable, Identifiable {

    case release
    case debug

    var id: Self { self }

    var displayName: String {
        switch self {
            case .release: "Release"
            case .debug: "Debug"
        }
    }

    var swiftly: BuildConfiguration {
        switch self {
            case .release: .release
            case .debug: .debug
        }
    }
    
}

enum ToolchainOption: Hashable {

    case automatic
    case exact(SwiftVersion)

    var displayName: String {
        switch self {
            case .automatic: "Automatic"
            case .exact(let version): "Swift \(version.description)"
        }
    }

    var swiftly: ToolchainSelection {
        switch self {
            case .automatic: .automatic
            case .exact(let version): .exact(version)
        }
    }
    
}
