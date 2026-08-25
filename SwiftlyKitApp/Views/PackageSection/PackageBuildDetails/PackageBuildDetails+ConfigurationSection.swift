import SwiftUI
import SwiftlyKit

extension PackageBuildDetails {

    struct ConfigurationSection: View {

        @Environment(BuildOptions.self) private var buildOptions

        var body: some View {
            @Bindable var buildOptions = buildOptions

            AdaptiveForm {
                configurationField("Product") {
                    menuPicker("Product", selection: $buildOptions.selectedProductName) {
                        Text("—").tag("")
                    }
                    .disabled(true)
                }

                configurationField("Target") {
                    menuPicker("Target", selection: $buildOptions.target) {
                        ForEach(BuildTarget.allCases, id: \.self) { target in
                            Text(target.displayName).tag(target)
                        }
                    }
                }

                configurationField("Configuration") {
                    menuPicker("Configuration", selection: $buildOptions.configuration) {
                        ForEach(BuildConfiguration.allCases, id: \.self) { configuration in
                            Text(configuration.displayName).tag(configuration)
                        }
                    }
                }

                configurationField("Swift") {
                    menuPicker("Swift", selection: $buildOptions.toolchain) {
                        Text(ToolchainSelection.automatic.displayName)
                            .tag(ToolchainSelection.automatic)
                    }
                }

                configurationField("Strip Binary") {
                    Toggle("Strip Binary", isOn: $buildOptions.stripBinary)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

    }

}

extension PackageBuildDetails.ConfigurationSection {

    @ViewBuilder
    private func configurationField<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {

        fieldLabel(title)
        content()
    }

    private func fieldLabel(_ title: String) -> some View {

        Text(title)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private func menuPicker<Selection: Hashable, Content: View>(
        _ title: String,
        selection: Binding<Selection>,
        @ViewBuilder content: () -> Content
    ) -> some View {

        Picker(title, selection: selection, content: content)
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

}
