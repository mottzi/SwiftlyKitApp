import SwiftUI
import SwiftlyKit

/// Swift toolchain picker and its contextual information button.
struct SwiftToolchainControl: View {

    @Binding var toolchain: ToolchainSelection
    @Binding var infoPopoverPresented: Bool

    var body: some View {
        HStack(spacing: ConfigurationAccessoryMetrics.spacing) {
            Picker("Swift", selection: $toolchain) {
                Text(ToolchainSelection.automatic.displayName)
                    .tag(ToolchainSelection.automatic)
            }
            .labelsHidden()
            .pickerStyle(.menu)

            BuildOptionInfoButton(
                isPresented: $infoPopoverPresented,
                option: .swift
            )
        }
    }

}
