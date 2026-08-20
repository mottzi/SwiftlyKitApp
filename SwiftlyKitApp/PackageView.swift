import SwiftlyKit

// MARK: - Display Name Extensions (used by ProjectCard)

public extension LinuxArchitecture {
    var displayName: String {
        switch self {
        case .x86_64: "x86_64 Linux"
        case .arm64: "ARM64 Linux"
        }
    }
}

public extension BuildConfiguration {
    var displayName: String {
        switch self {
        case .release: "Release"
        case .debug: "Debug"
        }
    }
}
