import Foundation
import Observation
import SwiftlyKit

@Observable
final class AppState {

    var packageURL: URL?

    var linuxTarget: LinuxTarget = .x86_64
    var buildStyle: BuildStyle = .release
    var selectedProductName = ""
    var toolchainOption: ToolchainOption = .automatic
    var stripBinary = false
    var showAdvanced = false

    var isFileImporterPresented = false

}

extension AppState {
    
    var isPackageSelected: Bool {
        packageURL != nil
    }

    var packageName: String {
        packageURL?.lastPathComponent ?? "Package"
    }

    var displayPath: String {
        guard let url = packageURL else { return "" }
        return Self.displayPath(for: url)
    }

    private static func displayPath(for url: URL) -> String {
        let path = url.path(percentEncoded: false)
        let home = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    func selectPackage(at url: URL) {
        if url.lastPathComponent == "Package.swift" {
            packageURL = url.deletingLastPathComponent()
        } else {
            packageURL = url
        }
        showAdvanced = false
    }

    func clearPackage() {
        packageURL = nil
    }
    
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
