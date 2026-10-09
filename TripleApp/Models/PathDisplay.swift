import Foundation

/// Formats filesystem paths for display in the app.
enum PathDisplay {

    /// Shortens a URL path under the current user's home directory to `~`.
    static func path(for url: URL) -> String {
        NSString(string: url.path(percentEncoded: false))
            .abbreviatingWithTildeInPath
    }

    /// Replaces complete home-directory prefixes in text with `~`.
    static func abbreviatingHomeDirectory(in text: String) -> String {
        guard let expression = homePathExpression else { return text }

        let range = NSRange(text.startIndex..., in: text)
        return expression.stringByReplacingMatches(
            in: text,
            range: range,
            withTemplate: "~"
        )
    }

}

extension PathDisplay {

    private static let homePathExpression: NSRegularExpression? = {
        var homePath = FileManager.default.homeDirectoryForCurrentUser
            .path(percentEncoded: false)
        while homePath.hasSuffix("/") { homePath.removeLast() }
        guard !homePath.isEmpty else { return nil }

        let escapedHomePath = NSRegularExpression.escapedPattern(for: homePath)
        let pattern = #"(?:^|(?<=[\s"'=(:\[]))"# + escapedHomePath + #"(?=/|$)"#
        return try? NSRegularExpression(pattern: pattern)
    }()

}
