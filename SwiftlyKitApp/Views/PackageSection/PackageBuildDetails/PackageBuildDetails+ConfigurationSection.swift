import SwiftUI
import SwiftlyKit

extension PackageBuildDetails {
    
    struct ConfigurationSection: View {

        @Environment(BuildOptions.self) private var buildOptions
        
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
                        menuPicker("Target", selection: $buildOptions.target) {
                            ForEach(BuildTarget.allCases, id: \.self) { target in
                                Text(target.displayName).tag(target)
                            }
                        }
                    }
                    
                    GridRow {
                        fieldLabel("Configuration")
                        menuPicker("Configuration", selection: $buildOptions.configuration) {
                            ForEach(BuildConfiguration.allCases, id: \.self) { configuration in
                                Text(configuration.displayName).tag(configuration)
                            }
                        }
                    }

                    GridRow {
                        fieldLabel("Swift")
                        menuPicker("Swift", selection: $buildOptions.toolchain) {
                            Text(ToolchainSelection.automatic.displayName)
                                .tag(ToolchainSelection.automatic)
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
