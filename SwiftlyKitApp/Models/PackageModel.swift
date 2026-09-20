import Foundation
import Observation

@Observable
/// Package selection state shared by the picker, configuration page, and build action.
final class PackageModel {

    /// Root URL of the selected Swift package.
    private(set) var packageURL: URL?

    /// Whether the selected package completed its transition to configuration.
    private(set) var isConfigurationReady = false

    /// Whether a valid Swift package is selected.
    var isPackageSelected: Bool {
        packageURL != nil
    }

    /// Page shown for the current package selection.
    var packagePage: Page {
        isPackageSelected ? .configuration : .picker
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

    /// Selects a different package root if `url` names an existing package directory or its `Package.swift` manifest.
    func selectPackage(at url: URL) {
        guard let packageURL = Self.swiftPackageRoot(for: url) else { return }
        guard packageURL != self.packageURL else { return }

        isConfigurationReady = false
        self.packageURL = packageURL
    }

    /// Enables discovery after the selected package finishes its page transition.
    func finishConfigurationTransition() {
        guard isPackageSelected else { return }
        isConfigurationReady = true
    }

    /// Clears the selected package and returns the package section to the picker.
    func clearPackage() {
        isConfigurationReady = false
        packageURL = nil
    }

    /// Page selected by the package model for the package section.
    enum Page: Int {

        /// Package selection page.
        case picker

        /// Selected package configuration page.
        case configuration

    }

}

extension PackageModel {

    /// Shortens paths under the user's home directory to use `~`.
    private static func displayPath(for url: URL) -> String {
        PathDisplay.path(for: url)
    }

}

extension PackageModel {

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
