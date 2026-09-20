import AppKit
import SwiftUI

/// Selectable live build output with copying, clearing, and optional bottom following.
struct BuildConsole: View {

    @State private var followsOutput = true
    @State private var wrapsLines = true
    @State private var scrollPhase = ScrollPhase.idle

    private var isUserScrolling: Bool {
        scrollPhase == .tracking || scrollPhase == .interacting || scrollPhase == .decelerating
    }

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
        .background(Color(nsColor: .textBackgroundColor).opacity(Self.backgroundOpacity))
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

            Toggle(isOn: $wrapsLines) {
                Label("Wrap Lines", systemImage: "arrow.turn.down.left")
            }
            .labelStyle(.iconOnly)
            .toggleStyle(.button)
            .help(wrapsLines ? "Stop wrapping build output" : "Wrap build output")

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
            ScrollView(wrapsLines ? .vertical : [.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(attributedLog)
                        .font(.system(.caption, design: .monospaced))
                        .lineSpacing(Self.lineSpacing)
                        .fixedSize(horizontal: !wrapsLines, vertical: true)
                        .frame(
                            maxWidth: wrapsLines ? .infinity : nil,
                            alignment: .leading
                        )
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Self.outputPadding)
                .id(Self.contentID)
            }
            .scrollBounceBehavior(.basedOnSize, axes: [.horizontal, .vertical])
            .defaultScrollAnchor(.topLeading, for: .alignment)
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
                guard !isUserScrolling else { return }
                scrollToBottom(using: proxy)
            }
            .onChange(of: followsOutput) { _, isFollowing in
                guard isFollowing else { return }
                scrollToBottom(using: proxy)
            }
            .onChange(of: wrapsLines) {
                scrollToBottomAfterLayout(using: proxy)
            }
            .onScrollGeometryChange(for: ScrollGeometry.self) { geometry in
                geometry
            } action: { oldGeometry, geometry in
                updateFollowing(from: oldGeometry, to: geometry)
            }
            .onScrollPhaseChange { _, phase, _ in
                scrollPhase = phase

                if phase == .idle {
                    scrollToBottom(using: proxy)
                }
            }
        }
    }

    private func updateFollowing(from oldGeometry: ScrollGeometry, to geometry: ScrollGeometry) {

        guard scrollPhase == .interacting || scrollPhase == .decelerating
            || (scrollPhase == .idle && geometry.contentOffset.y < oldGeometry.contentOffset.y)
        else { return }
        guard oldGeometry.contentOffset.y != geometry.contentOffset.y else { return }
        guard oldGeometry.containerSize == geometry.containerSize else { return }
        guard oldGeometry.contentInsets == geometry.contentInsets else { return }
        guard oldGeometry.contentSize.width == geometry.contentSize.width else { return }
        guard geometry.contentSize.height >= oldGeometry.contentSize.height else { return }

        if geometry.contentOffset.y + geometry.containerSize.height
            >= geometry.contentSize.height + geometry.contentInsets.bottom - Self.bottomTolerance {
            guard scrollPhase != .idle else { return }
            if !followsOutput {
                followsOutput = true
            }
        } else if followsOutput {
            followsOutput = false
        }
    }

    private var attributedLog: AttributedString {
        var text = AttributedString()

        for index in entries.indices {
            if index != entries.startIndex {
                text.append(AttributedString("\n"))
            }

            let entry = entries[index]
            var line = AttributedString(
                entry.kind.visiblePrefix + (entry.displayText.isEmpty ? " " : entry.displayText)
            )
            line.foregroundColor = entry.kind.foregroundStyle
            text.append(line)
        }

        return text
    }

    private func scrollToBottom(using proxy: ScrollViewProxy) {
        guard followsOutput else { return }
        proxy.scrollTo(
            Self.contentID,
            anchor: wrapsLines ? .bottom : .bottomLeading
        )
    }

    private func scrollToBottomAfterLayout(using proxy: ScrollViewProxy) {
        guard followsOutput else { return }

        Task { @MainActor in
            await Task.yield()
            guard !isUserScrolling else { return }
            scrollToBottom(using: proxy)
        }
    }

}

extension BuildLogEntry.Kind {

    fileprivate var visiblePrefix: String {
        switch self {
            case .status: "› "
            case .command: "$ "
            case .standardOutput: "  "
            case .standardError: "! "
            case .success: "✓ "
            case .failure: "! "
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

    private static let contentID = "build-console-content"
    private static let bottomTolerance: CGFloat = 2
    private static let minimumHeight: CGFloat = 112
    private static let toolbarHeight: CGFloat = 27
    private static let toolbarPadding: CGFloat = 8
    private static let outputPadding: CGFloat = 8
    private static let actionSpacing: CGFloat = 3
    private static let lineSpacing: CGFloat = 1
    private static let dividerOpacity = 0.45
    private static let backgroundOpacity = 0.5

}
