import SwiftUI

extension PackageBuildDetails {
    
    struct ConfigurationSection: View {

        @Environment(PackageModel.self) private var packageModel
        @Environment(BuildOptions.self) private var buildOptions
        @State private var showAdvanced = false
        
        var body: some View {
            @Bindable var buildOptions = buildOptions
            
            VStack(alignment: .leading, spacing: 8) {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        fieldLabel("Product")
                        menuPicker("Product", selection: $buildOptions.selectedProductName) {
                            Text("—").tag("")
                        }
                        .disabled(true)
                    }
                    
                    GridRow {
                        fieldLabel("Target")
                        menuPicker("Target", selection: $buildOptions.linuxTarget) {
                            ForEach(LinuxTarget.allCases) { target in
                                Text(target.displayName).tag(target)
                            }
                        }
                    }
                    
                    GridRow {
                        fieldLabel("Configuration")
                        menuPicker("Configuration", selection: $buildOptions.buildStyle) {
                            ForEach(BuildStyle.allCases) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                    }
                }
                
                DisclosureGroup(isExpanded: $showAdvanced) {
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                        GridRow {
                            fieldLabel("Swift")
                            menuPicker("Swift", selection: $buildOptions.toolchainOption) {
                                Text("Automatic").tag(ToolchainOption.automatic)
                            }
                        }
                        
                        GridRow {
                            fieldLabel("Strip Binary")
                            Toggle("Strip Binary", isOn: $buildOptions.stripBinary)
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
            .onChange(of: packageModel.packageURL) {
                showAdvanced = false
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
