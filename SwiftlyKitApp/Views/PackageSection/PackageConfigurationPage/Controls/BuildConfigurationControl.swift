import SwiftUI
import SwiftlyKit

/// Build configuration picker and its contextual information button.
struct BuildConfigurationControl: View {

    @Binding var configuration: BuildConfiguration
    @Binding var infoPopoverPresented: Bool

    var body: some View {
        HStack(spacing: ConfigurationAccessoryMetrics.spacing) {
            Picker("Configuration", selection: $configuration) {
                ForEach(BuildConfiguration.allCases, id: \.self) { configuration in
                    Text(configuration.displayName).tag(configuration)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            BuildOptionInfoButton(
                isPresented: $infoPopoverPresented,
                option: .configuration
            )
        }
    }

}
