import SwiftUI
import SwiftlyKit

/// Target picker and its contextual information button.
struct TargetControl: View {

    @Binding var target: BuildTarget
    @Binding var infoPopoverPresented: Bool

    var body: some View {
        HStack(spacing: ConfigurationAccessoryMetrics.spacing) {
            Picker("Target", selection: $target) {
                ForEach(BuildTarget.allCases, id: \.self) { target in
                    Text(target.displayName).tag(target)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            BuildOptionInfoButton(
                isPresented: $infoPopoverPresented,
                option: .target
            )
        }
    }

}
