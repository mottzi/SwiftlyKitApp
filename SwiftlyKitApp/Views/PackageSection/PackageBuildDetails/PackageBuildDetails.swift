import SwiftUI
import SwiftlyKit

struct PackageBuildDetails: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        VStack(alignment: .leading, spacing: 14) {
            Header()
            Divider()
                .opacity(0.55)
            ConfigurationSection()
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary.opacity(0.38))
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    // MARK: - Configuration

    private struct ConfigurationSection: View {

        @Environment(AppState.self) private var appState

        var body: some View {
            @Bindable var appState = appState

            VStack(alignment: .leading, spacing: 8) {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        fieldLabel("Product")
                        menuPicker("Product", selection: $appState.selectedProductName) {
                            Text("—").tag("")
                        }
                        .disabled(true)
                    }

                    GridRow {
                        fieldLabel("Target")
                        menuPicker("Target", selection: $appState.linuxTarget) {
                            ForEach(LinuxTarget.allCases) { target in
                                Text(target.displayName).tag(target)
                            }
                        }
                    }

                    GridRow {
                        fieldLabel("Configuration")
                        menuPicker("Configuration", selection: $appState.buildStyle) {
                            ForEach(BuildStyle.allCases) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                    }
                }

                DisclosureGroup(isExpanded: $appState.showAdvanced) {
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                        GridRow {
                            fieldLabel("Swift")
                            menuPicker("Swift", selection: $appState.toolchainOption) {
                                Text("Automatic").tag(ToolchainOption.automatic)
                            }
                        }

                        GridRow {
                            fieldLabel("Strip Binary")
                            Toggle("Strip Binary", isOn: $appState.stripBinary)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .controlSize(.small)
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    Text("Advanced")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }

        private func fieldLabel(_ title: String) -> some View {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.leading)
                .frame(width: 108, alignment: .leading)
        }

        private func menuPicker<Selection: Hashable, Content: View>(
            _ title: String,
            selection: Binding<Selection>,
            @ViewBuilder content: () -> Content
        ) -> some View {
            Picker(title, selection: selection, content: content)
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 240, alignment: .leading)
                .gridColumnAlignment(.leading)
        }
    }
}

// MARK: - Menu

struct PackageMenu: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        Menu {
            if let url = appState.packageURL {
                Button("Show in Finder", systemImage: "folder") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }

                Button("Copy Path", systemImage: "doc.on.doc") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(
                        url.path(percentEncoded: false),
                        forType: .string
                    )
                }
            }

            Button("Choose Another Package…", systemImage: "folder.badge.plus") {
                appState.isFileImporterPresented = true
            }

            Divider()

            Button("Close Package", systemImage: "xmark.circle", role: .destructive) {
                appState.clearPackage()
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .contentShape(.rect)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("Package actions")
        .accessibilityLabel("Package actions")
    }
}

#Preview {
    AppView()
        .environment(AppState())
        .frame(width: 500, height: 300)
}
