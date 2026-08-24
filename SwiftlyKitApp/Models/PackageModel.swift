import Foundation
import Observation

@MainActor
@Observable
final class PackageModel {

    var packageURL: URL?

    var isPackageSelected: Bool {
        packageURL != nil
    }

    var packagePage: PackagePage {
        isPackageSelected ? .details : .picker
    }

    var packageName: String {
        packageURL?.lastPathComponent ?? "Package"
    }

    var displayPath: String {
        guard let url = packageURL else { return "" }
        return Self.displayPath(for: url)
    }

    func selectPackage(at url: URL) {
        if url.lastPathComponent == "Package.swift" {
            packageURL = url.deletingLastPathComponent()
        } else {
            packageURL = url
        }
    }

    func clearPackage() {
        packageURL = nil
    }

    private static func displayPath(for url: URL) -> String {
        let path = url.path(percentEncoded: false)
        let home = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
    
}

enum PackagePage: Int {
    case picker
    case details
}
