import AppKit
import SwiftUI

/// Selectable live build output with copying, clearing, and optional bottom following.
struct BuildConsole: View {

    @State private var followsOutput = true

    let entries: [BuildLogEntry]
    let logRevision: Int
    let logText: String
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            consoleToolbar
            Divider()
                .opacity(Self.dividerOpacity)
            consoleScrollView
        }
        .frame(minHeight: Self.minimumHeight)
        .background {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(Color(nsColor: .textBackgroundColor).opacity(Self.backgroundOpacity))
        }
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .strokeBorder(Color.primary.opacity(Self.borderOpacity))
        }
    }

}

extension BuildConsole {

    private var consoleToolbar: some View {
        HStack(spacing: Self.actionSpacing) {
            Text("Build Output")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Toggle(isOn: $followsOutput) {
                Label("Follow Output", systemImage: "arrow.down.to.line")
            }
            .labelStyle(.iconOnly)
            .toggleStyle(.button)
            .help(followsOutput ? "Stop following build output" : "Follow build output")

            Button("Copy Build Output", systemImage: "doc.on.doc", action: copyLog)
                .labelStyle(.iconOnly)
                .disabled(logText.isEmpty)
                .help("Copy build output")

            Button("Clear Build Output", systemImage: "trash", action: onClear)
                .labelStyle(.iconOnly)
                .disabled(entries.isEmpty)
                .help("Clear build output")
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .padding(.horizontal, Self.toolbarPadding)
        .frame(height: Self.toolbarHeight)
    }

    private func copyLog() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(logText, forType: .string)
    }

    private var consoleScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Self.lineSpacing) {
                    ForEach(entries) { entry in
                        BuildLogRow(entry: entry)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(Self.bottomID)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Self.outputPadding)
                .textSelection(.enabled)
            }
            .overlay {
                if entries.isEmpty {
                    Text("Build output appears here.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                scrollToBottom(using: proxy)
            }
            .onChange(of: logRevision) { _, _ in
                scrollToBottom(using: proxy)
            }
            .onChange(of: followsOutput) { _, isFollowing in
                guard isFollowing else { return }
                proxy.scrollTo(Self.bottomID, anchor: .bottom)
            }
        }
    }

    private func scrollToBottom(using proxy: ScrollViewProxy) {
        guard followsOutput else { return }
        proxy.scrollTo(Self.bottomID, anchor: .bottom)
    }

}

private struct BuildLogRow: View {

    let entry: BuildLogEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Self.spacing) {
            Text(entry.kind.visiblePrefix)
                .foregroundStyle(entry.kind.foregroundStyle)
                .frame(width: Self.prefixWidth, alignment: .trailing)

            Text(entry.text.isEmpty ? " " : entry.text)
                .foregroundStyle(entry.kind.foregroundStyle)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(.caption, design: .monospaced))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

}

extension BuildLogRow {

    private static let spacing: CGFloat = 6
    private static let prefixWidth: CGFloat = 9

}

extension BuildLogEntry.Kind {

    fileprivate var visiblePrefix: String {
        switch self {
            case .status: "›"
            case .command: "$"
            case .standardOutput: ""
            case .standardError: "!"
            case .success: "✓"
            case .failure: "!"
        }
    }

    fileprivate var foregroundStyle: Color {
        switch self {
            case .status: .secondary
            case .command: .accentColor
            case .standardOutput: .primary
            case .standardError, .failure: .red
            case .success: .green
        }
    }

}

extension BuildConsole {

    private static let bottomID = "build-console-bottom"
    private static let minimumHeight: CGFloat = 112
    private static let toolbarHeight: CGFloat = 27
    private static let toolbarPadding: CGFloat = 8
    private static let outputPadding: CGFloat = 8
    private static let actionSpacing: CGFloat = 3
    private static let lineSpacing: CGFloat = 1
    private static let cornerRadius: CGFloat = 7
    private static let dividerOpacity = 0.45
    private static let backgroundOpacity = 0.5
    private static let borderOpacity = 0.07

}
