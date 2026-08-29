import Foundation
import Observation
import SwiftlyKit

@Observable
/// Bounded line-oriented transcript of SwiftlyKit build events.
final class BuildLog {

    /// Lines currently available to the build console.
    private(set) var entries: [BuildLogEntry] = []

    /// Revision that changes for complete and partial line updates.
    private(set) var revision = 0

    @ObservationIgnored private var nextEntryID = 0

    /// Appends one progress, command, or subprocess output event.
    func append(_ event: SwiftlyKitEvent) {
        switch event {
            case .progress(let progress):
                append(progress.detail, kind: .status)
            case .command(let command):
                append(Self.commandDescription(command), kind: .command)
            case .output(let output):
                append(output)
        }
    }

    /// Records the selected product, configuration, toolchain, and stripping choice for a new build.
    func appendBuildStart(
        for preparedPackage: PreparedPackage,
        configuration: BuildConfiguration,
        stripBinary: Bool
    ) {
        let configuration = switch configuration {
            case .debug: "debug"
            case .release: "release"
        }
        let stripDescription = stripBinary ? ", stripping enabled" : ""

        append(
            "Starting \(configuration) build of \(preparedPackage.selectedProduct.name) with Swift "
                + "\(preparedPackage.environment.swiftVersion)\(stripDescription).",
            kind: .status
        )
    }

    /// Appends one complete app-generated console line.
    func append(_ text: String, kind: BuildLogEntry.Kind) {
        completePartialLine()
        appendEntry(text, kind: kind, isComplete: true)
        trim()
        revision += 1
    }

    /// Removes all current console lines.
    func clear() {
        entries.removeAll(keepingCapacity: true)
        nextEntryID = 0
        revision += 1
    }

    /// Plain text for copying the current build console.
    var text: String {
        entries.map(\.plainText).joined(separator: "\n")
    }

}

extension BuildLog {

    private func append(_ output: CommandOutputChunk) {
        let kind: BuildLogEntry.Kind = switch output.stream {
            case .standardOutput: .standardOutput
            case .standardError: .standardError
        }
        let text = output.text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = text.split(
            separator: "\n",
            omittingEmptySubsequences: false
        )

        for index in lines.indices {
            appendOutputLine(
                String(lines[index]),
                kind: kind,
                isComplete: index < lines.index(before: lines.endIndex)
            )
        }

        trim()
        revision += 1
    }

    private func appendOutputLine(_ text: String, kind: BuildLogEntry.Kind, isComplete: Bool) {
        if let lastIndex = entries.indices.last,
           entries[lastIndex].kind == kind,
           !entries[lastIndex].isComplete {
            entries[lastIndex].text.append(text)
            entries[lastIndex].isComplete = isComplete
            return
        }

        guard !text.isEmpty || isComplete else { return }
        appendEntry(text, kind: kind, isComplete: isComplete)
    }

    private func appendEntry(_ text: String, kind: BuildLogEntry.Kind, isComplete: Bool) {
        entries.append(
            BuildLogEntry(
                id: nextEntryID,
                kind: kind,
                text: text,
                isComplete: isComplete
            )
        )
        nextEntryID += 1
    }

    private func completePartialLine() {
        guard let lastIndex = entries.indices.last else { return }
        entries[lastIndex].isComplete = true
    }

    private func trim() {
        guard entries.count > Self.maximumEntryCount else { return }
        entries.removeFirst(entries.count - Self.maximumEntryCount)
    }

}

extension BuildLog {

    private static func commandDescription(_ command: CommandInvocation) -> String {
        ([command.executable.path(percentEncoded: false)] + command.arguments)
            .map(quotedCommandArgument)
            .joined(separator: " ")
    }

    private static func quotedCommandArgument(_ argument: String) -> String {
        guard argument.contains(where: { $0.isWhitespace }) else { return argument }
        return "\"\(argument.replacingOccurrences(of: "\"", with: "\\\""))\""
    }

}

extension BuildLog {

    private static let maximumEntryCount = 5_000

}
