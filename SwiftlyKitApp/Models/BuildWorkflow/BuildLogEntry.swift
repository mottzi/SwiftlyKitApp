/// One styled line in the live build console.
struct BuildLogEntry: Identifiable, Equatable {

    let id: Int
    let kind: Kind
    var text: String
    var isComplete: Bool

    /// Text copied for this line, including its semantic console prefix.
    var plainText: String {
        kind.plainTextPrefix + text
    }

    /// Text rendered for this line with the home directory abbreviated.
    var displayText: String {
        PathDisplay.abbreviatingHomeDirectory(in: text)
    }

    /// Semantic source and severity of one console line.
    enum Kind: Equatable {
        case status
        case command
        case standardOutput
        case standardError
        case success
        case failure
    }

}

extension BuildLogEntry.Kind {

    fileprivate var plainTextPrefix: String {
        switch self {
            case .status: "> "
            case .command: "$ "
            case .standardOutput: ""
            case .standardError: "! "
            case .success: "✓ "
            case .failure: "✕ "
        }
    }

}
