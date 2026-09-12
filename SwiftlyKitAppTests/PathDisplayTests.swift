import Foundation
import Testing
@testable import SwiftlyKitApp

@MainActor
struct PathDisplayTests {

    @Test(arguments: ["Development/Swift/Package", "é/工具", "Build/My Product"])
    func abbreviatesHomeDirectoryInPathsAndText(relativePath: String) {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: relativePath, directoryHint: .notDirectory)
        let fullPath = url.path(percentEncoded: false)

        #expect(PathDisplay.path(for: url) == "~/\(relativePath)")
        #expect(
            PathDisplay.abbreviatingHomeDirectory(in: "Build succeeded: \(fullPath)")
                == "Build succeeded: ~/\(relativePath)"
        )
    }

    @Test
    func abbreviatesHomeDirectoryWithAndWithoutATrailingSlash() {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path

        #expect(PathDisplay.abbreviatingHomeDirectory(in: homePath) == "~")
        #expect(PathDisplay.abbreviatingHomeDirectory(in: homePath + "/") == "~/")
    }

    @Test
    func preservesDelimitersAroundMultiplePaths() {
        let homePath = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "project", directoryHint: .notDirectory)
            .path(percentEncoded: false)
        let text = "--path='\(homePath)/My Package' (\(homePath)/é.swift:12) [\(homePath)]"

        #expect(
            PathDisplay.abbreviatingHomeDirectory(in: text)
                == "--path='~/project/My Package' (~/project/é.swift:12) [~/project]"
        )
    }

    @Test(arguments: ["Work", "é", ".backup", "-other", "_other", " Work", "(backup)", ",copy"])
    func preservesOtherHomeDirectoryNames(suffix: String) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let path = home.deletingLastPathComponent()
            .appending(path: home.lastPathComponent + suffix + "/project", directoryHint: .notDirectory)
            .path(percentEncoded: false)
        let text = "Build succeeded: \(path)"

        #expect(PathDisplay.abbreviatingHomeDirectory(in: text) == text)
    }

    @Test
    func preservesHomeDirectoryTextInsideAnotherPathOrURL() {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "project", directoryHint: .notDirectory)
            .path(percentEncoded: false)
        let text = "Backup: /Volumes/Backup\(path), URL: file://\(path)"

        #expect(PathDisplay.abbreviatingHomeDirectory(in: text) == text)
    }

    @Test
    func keepsCopiedLogTextRawWhileDisplayTextUsesTheShortPath() {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Build/Product", directoryHint: .notDirectory)
            .path(percentEncoded: false)
        let entry = BuildLogEntry(
            id: 0,
            kind: .success,
            text: "Build succeeded: \(path)",
            isComplete: true
        )

        #expect(entry.displayText == "Build succeeded: ~/Build/Product")
        #expect(entry.plainText == "✓ Build succeeded: \(path)")
    }

}
