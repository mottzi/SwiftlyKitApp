import SwiftUI
import SwiftlyKit

/// Swift toolchain picker and its contextual information button.
struct SwiftToolchainControl: View {

    @Binding var toolchain: ToolchainSelection
    @Binding var infoPopoverPresented: Bool

    var body: some View {
        HStack(spacing: Constants.configurationAccessorySpacing) {
            Picker("Swift", selection: $toolchain) {
                Text(ToolchainSelection.automatic.displayName)
                    .tag(ToolchainSelection.automatic)
            }
            .labelsHidden()
            .pickerStyle(.menu)

            ConfigurationInfoButton(
                isPresented: $infoPopoverPresented,
                option: .swift
            )
        }
    }

}
