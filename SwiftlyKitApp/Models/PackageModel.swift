import Foundation
import Observation

/// Package selection state shared by the picker, details page, and toolbar.
@Observable
final class PackageModel {

    /// Root URL of the selected Swift package.
    private(set) var packageURL: URL?

    /// Whether a valid Swift package is selected.
    var isPackageSelected: Bool {
        packageURL != nil
    }

    /// Page shown for the current package selection.
    var packagePage: PackagePage {
        isPackageSelected ? .details : .picker
    }

    /// Name shown for the selected package, or `Package` before selection.
    var packageName: String {
        packageURL?.lastPathComponent ?? "Package"
    }

    /// Path shown for the selected package, with the home directory abbreviated as `~`.
    var displayPath: String {
        guard let url = packageURL else { return "" }
        return Self.displayPath(for: url)
    }

    /// Selects the package root if `url` names an existing package directory or its `Package.swift` manifest.
    func selectPackage(at url: URL) {
        guard let packageURL = Self.swiftPackageRoot(for: url) else { return }
        self.packageURL = packageURL
    }

    /// Clears the selected package and returns the package section to the picker.
    func clearPackage() {
        packageURL = nil
    }

}

extension PackageModel {

    /// Shortens paths under the user's home directory to use `~`.
    private static func displayPath(for url: URL) -> String {

        let path = url.path(percentEncoded: false)
        let home = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        if path == home || path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    /// Finds the package root from an existing package directory or its regular `Package.swift` manifest.
    private static func swiftPackageRoot(for url: URL) -> URL? {

        let url = url.standardizedFileURL
        var isDirectory = ObjCBool(false)
        let urlExists = FileManager.default.fileExists(
            atPath: url.path(percentEncoded: false),
            isDirectory: &isDirectory
        )
        guard urlExists else { return nil }

        let packageURL: URL
        if isDirectory.boolValue {
            packageURL = url
        } else {
            guard url.lastPathComponent == "Package.swift" else { return nil }
            packageURL = url.deletingLastPathComponent()
        }

        let manifestURL = packageURL.appendingPathComponent("Package.swift")
        var manifestIsDirectory = ObjCBool(false)
        let manifestExists = FileManager.default.fileExists(
            atPath: manifestURL.path(percentEncoded: false),
            isDirectory: &manifestIsDirectory
        )
        guard manifestExists, !manifestIsDirectory.boolValue else { return nil }

        return packageURL
    }

}

/// Page selected by `PackageModel` for the package section.
enum PackagePage: Int {

    /// Package selection page.
    case picker

    /// Selected package details page.
    case details
}
