import SwiftUI

extension PackageBuildDetails {
    
    struct ConfigurationSection: View {

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
        
    }
    
}

extension PackageBuildDetails.ConfigurationSection {
    
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
