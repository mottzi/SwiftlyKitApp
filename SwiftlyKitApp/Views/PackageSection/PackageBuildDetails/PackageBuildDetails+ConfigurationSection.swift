import SwiftUI
import SwiftlyKit

extension PackageBuildDetails {

    struct ConfigurationSection: View {

        @Environment(BuildOptions.self) private var buildOptions

        var body: some View {
            @Bindable var buildOptions = buildOptions

            LabelControlGrid {
                configurationField {
                    Text("Product")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } control: {
                    Picker("Product", selection: $buildOptions.selectedProduct) {
                        Text("—").tag(nil as ExecutableProduct?)
                        ForEach(buildOptions.availableProducts, id: \.name) { product in
                            Text(product.name).tag(product as ExecutableProduct?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .disabled(buildOptions.availableProducts.isEmpty)
                }

                configurationField {
                    Text("Target")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } control: {
                    Picker("Target", selection: $buildOptions.target) {
                        ForEach(BuildTarget.allCases, id: \.self) { target in
                            Text(target.displayName).tag(target)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                configurationField {
                    Text("Configuration")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } control: {
                    Picker("Configuration", selection: $buildOptions.configuration) {
                        ForEach(BuildConfiguration.allCases, id: \.self) { configuration in
                            Text(configuration.displayName).tag(configuration)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                configurationField {
                    Text("Swift")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } control: {
                    Picker("Swift", selection: $buildOptions.toolchain) {
                        Text(ToolchainSelection.automatic.displayName)
                            .tag(ToolchainSelection.automatic)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                configurationField {
                    Text("Strip Binary")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } control: {
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
    private func configurationField<Label: View, Control: View>(
        @ViewBuilder _ label: () -> Label,
        @ViewBuilder control: () -> Control
    ) -> some View {

        label()
        control()
    }

}
