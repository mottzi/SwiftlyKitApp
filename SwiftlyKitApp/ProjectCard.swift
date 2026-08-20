import SwiftUI
import SwiftlyKit
import UniformTypeIdentifiers

/// A single persistent card that morphs between the package selector (empty state)
/// and the package configuration view (selected state).
///
/// Every shared visual element (icon, title, background, border) is ALWAYS in the
/// view hierarchy. State changes drive property animations (opacity, frame, color)
/// rather than view insertion/removal. This eliminates crossfade artifacts entirely.
struct ProjectCard: View {

    @Binding var packageURL: URL?

    // MARK: - Selector interaction state
    @State private var isFileImporterPresented = false
    @State private var isDropTargeted = false
    @State private var isHovering = false
    @State private var isPressed = false

    // MARK: - Package view state
    @State private var products: [String] = ["my-server", "my-tool"]
    @State private var selectedProduct: String = "my-server"
    @State private var selectedTarget: LinuxArchitecture = .x86_64
    @State private var selectedConfiguration: BuildConfiguration = .release
    @State private var environmentStatus: MockEnvironmentStatus = .ready(description: "Swift 6.3.3 · Static Linux SDK · Ready")
    @State private var showAdvanced = false
    @State private var stripBinary = true
    @State private var selectedSwiftVersion = "Automatic (Swift 6.3.3)"

    private var isSelected: Bool { packageURL != nil }

    private var packageName: String {
        packageURL?.lastPathComponent ?? "Package"
    }

    private var displayPath: String {
        guard let url = packageURL else { return "" }
        let path = url.path(percentEncoded: false)
        let home = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    // MARK: - Body

    var body: some View {
        cardContent
            .background { cardBackground }
            .overlay { cardBorder }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(containerScale)
            .geometryGroup()
            .animation(.appSpring(response: 0.45, dampingFraction: 0.75), value: isSelected)
            .animation(.appSpring(response: 0.35, dampingFraction: 0.65), value: isDropTargeted)
            .animation(.appSpring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .animation(.appSpring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onTapGesture {
                if !isSelected {
                    isFileImporterPresented = true
                }
            }
            .onHover { hovering in
                isHovering = isSelected ? false : hovering
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.folder]
            ) { result in
                if case .success(let url) = result {
                    withAppAnimation {
                        handleSelection(url)
                    }
                }
            }
            .dropDestination(for: URL.self) { items, _ in
                guard let url = items.first else { return false }
                withAppAnimation {
                    handleSelection(url)
                }
                return true
            } isTargeted: { targeted in
                isDropTargeted = targeted
            }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: isSelected ? 16 : 0) {
            headerSection

            if isSelected {
                Divider()
                    .opacity(0.6)

                configurationSection

                environmentStatusRow
            }
        }
        .padding(isSelected ? 16 : 0)
    }

    // MARK: - Header (always present)

    private var headerSection: some View {
        HStack(spacing: isSelected ? 12 : 16) {
            swiftIcon
            titleArea
            
            Spacer()
                .frame(maxWidth: isSelected ? .infinity : 0)
            
            packageMenu
                .opacity(isSelected ? 1 : 0)
                .allowsHitTesting(isSelected)
        }
        .frame(maxWidth: .infinity, maxHeight: isSelected ? nil : .infinity)
    }

    // MARK: Swift Icon (always present — animated frame/color)

    private var swiftIcon: some View {
        Image(systemName: "swift")
            .resizable()
            .scaledToFit()
            .foregroundStyle(iconColor)
            .rotationEffect(iconRotation)
            .frame(width: isSelected ? 24 : 80, height: isSelected ? 24 : 80)
            .padding(isSelected ? 8 : 0)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(isSelected ? 0.12 : 0))
            )
    }

    // MARK: Title Area (always present — both labels overlaid, opacity-driven)

    private var titleArea: some View {
        ZStack(alignment: .topLeading) {
            // Selected state: package name + path
            VStack(alignment: .leading, spacing: 2) {
                Text(packageName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(displayPath)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .opacity(isSelected ? 1 : 0)

            // Empty state: selector label
            ZStack(alignment: .leading) {
                // Hidden sizing placeholders prevent layout shift on hover
                Text("Drop Package here").hidden()
                Text("Select Package").hidden()
                Text("Drop to Select").hidden()
                Text(selectorLabelText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .font(.largeTitle)
            .fontWeight(isDropTargeted ? .medium : .light)
            .foregroundStyle(selectorLabelColor)
            .opacity(isSelected ? 0 : 1)
        }
    }

    // MARK: - Card Background (always present — animated fill)

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected
                ? Color(nsColor: .controlBackgroundColor).opacity(0.85)
                : Color.orange.opacity(selectorBackgroundOpacity)
            )
    }

    // MARK: - Card Border (both always present — opacity-driven)

    private var cardBorder: some View {
        ZStack {
            // Selected state: thin solid border
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDropTargeted ? Color.orange : Color.primary.opacity(0.08),
                    lineWidth: isDropTargeted ? 2 : 1
                )
                .opacity(isSelected ? 1 : 0)

            // Empty state: dashed border
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(
                        lineWidth: isDropTargeted ? 2.5 : 2,
                        dash: isDropTargeted ? [10, 6] : [8, 6],
                        dashPhase: isDropTargeted ? -12 : (isHovering ? (isPressed ? -12 : -6) : 0)
                    )
                )
                .foregroundStyle(isDropTargeted || isHovering ? .orange : .secondary)
                .opacity(isSelected ? 0 : 1)
        }
    }

    // MARK: - Selector State Helpers

    private var selectorLabelText: String {
        if isDropTargeted { return "Drop to Select" }
        return isHovering ? "Select Package" : "Drop Package here"
    }

    private var selectorLabelColor: Color {
        if isDropTargeted { return .orange }
        return isHovering ? .primary : .secondary
    }

    private var iconColor: Color {
        if isSelected || isDropTargeted || isHovering { return .orange }
        return .secondary
    }

    private var iconRotation: Angle {
        if isSelected || isDropTargeted { return .degrees(0) }
        if isHovering { return .degrees(isPressed ? 2 : 4) }
        return .degrees(0)
    }

    private var selectorBackgroundOpacity: Double {
        if isPressed { return 0.10 }
        if isDropTargeted { return 0.12 }
        if isHovering { return 0.04 }
        return 0.0
    }

    private var containerScale: CGFloat {
        guard !isSelected else { return 1.0 }
        if isPressed { return 0.98 }
        if isDropTargeted { return 1.02 }
        return 1.0
    }

    // MARK: - Configuration Controls (inserted when selected)

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            configRow("Product") {
                if products.count > 1 {
                    Picker("Product", selection: $selectedProduct) {
                        ForEach(products, id: \.self) { Text($0).tag($0) }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: 220, alignment: .leading)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "terminal")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(selectedProduct)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 3)
                }
            }

            configRow("Target") {
                Picker("Target", selection: $selectedTarget) {
                    Text(LinuxArchitecture.x86_64.displayName).tag(LinuxArchitecture.x86_64)
                    Text(LinuxArchitecture.arm64.displayName).tag(LinuxArchitecture.arm64)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 220, alignment: .leading)
            }

            configRow("Configuration") {
                Picker("Configuration", selection: $selectedConfiguration) {
                    Text(BuildConfiguration.release.displayName).tag(BuildConfiguration.release)
                    Text(BuildConfiguration.debug.displayName).tag(BuildConfiguration.debug)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 220, alignment: .leading)
            }

            advancedDisclosure
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func configRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            content()
            Spacer()
        }
    }

    private var advancedDisclosure: some View {
        DisclosureGroup(isExpanded: $showAdvanced) {
            VStack(alignment: .leading, spacing: 8) {
                configRow("Swift Toolchain") {
                    Picker("Swift Toolchain", selection: $selectedSwiftVersion) {
                        Text("Automatic (Swift 6.3.3)").tag("Automatic (Swift 6.3.3)")
                        Text("Swift 6.3.3").tag("Swift 6.3.3")
                        Text("Swift 6.3.2").tag("Swift 6.3.2")
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: 220, alignment: .leading)
                }

                configRow("Strip Binary") {
                    Toggle("", isOn: $stripBinary)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            }
            .padding(.top, 4)
        } label: {
            Text("Advanced")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .animation(.appSpring(response: 0.3, dampingFraction: 0.7), value: showAdvanced)
    }

    // MARK: - Environment Status

    @ViewBuilder
    private var environmentStatusRow: some View {
        switch environmentStatus {
        case .ready(let description):
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.green)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 2)
            .transition(.opacity)

        case .installRequired(let toolchain, let sdk):
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
                Text("\(toolchain) and its \(sdk) are required.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Button("Install") { startMockInstall() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )

        case .installing(let toolchain, let progress):
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Installing \(toolchain)…")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                }
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
    }

    // MARK: - Package Menu

    private var packageMenu: some View {
        Menu {
            if let url = packageURL {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                }

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url.path(percentEncoded: false), forType: .string)
                } label: {
                    Label("Copy Path", systemImage: "doc.on.doc")
                }
            }

            Button {
                isFileImporterPresented = true
            } label: {
                Label("Choose Another Package…", systemImage: "arrow.triangle.2.circlepath")
            }

            Divider()

            Button(role: .destructive) {
                withAppAnimation {
                    packageURL = nil
                    isHovering = false
                }
            } label: {
                Label("Close Package", systemImage: "xmark.circle")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .frame(width: 28, height: 28)
        .help("Package Actions")
    }

    // MARK: - Actions

    private func handleSelection(_ url: URL) {
        if url.lastPathComponent == "Package.swift" {
            packageURL = url.deletingLastPathComponent()
        } else {
            packageURL = url
        }
    }

    private func startMockInstall() {
        environmentStatus = .installing(toolchain: "Swift 6.3.3", progress: 0.1)
        Task { @MainActor in
            for step in 1...10 {
                try? await Task.sleep(for: .milliseconds(200))
                environmentStatus = .installing(toolchain: "Swift 6.3.3", progress: Double(step) / 10.0)
            }
            environmentStatus = .ready(description: "Swift 6.3.3 · Static Linux SDK · Ready")
        }
    }

}

// MARK: - Previews

#Preview {
    ContentView()
        .frame(width: 500, height: 300)
}
