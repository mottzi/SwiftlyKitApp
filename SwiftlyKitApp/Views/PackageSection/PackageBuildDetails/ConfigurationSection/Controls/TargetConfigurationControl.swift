import SwiftUI
import SwiftlyKit

/// Target picker and its contextual information button.
struct TargetConfigurationControl: View {

    @Binding var target: BuildTarget
    @Binding var infoPopoverPresented: Bool

    var body: some View {
        HStack(spacing: Constants.configurationAccessorySpacing) {
            Picker("Target", selection: $target) {
                ForEach(BuildTarget.allCases, id: \.self) { target in
                    Text(target.displayName).tag(target)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            ConfigurationInfoButton(
                isPresented: $infoPopoverPresented,
                option: .target
            )
        }
    }

}
