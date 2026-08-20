import Foundation
import Observation

@Observable
final class AppState {

    var packageURL: URL?

}

extension AppState {
    
    var isPackageSelected: Bool {
        packageURL != nil
    }

    var packagePage: PackagePage? {
        get { isPackageSelected ? .project : .selector }
        set {
            if newValue == .selector {
                clearPackage()
            }
        }
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
    
}

enum PackagePage: Hashable {
    case selector
    case project
}
