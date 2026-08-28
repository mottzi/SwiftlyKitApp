import SwiftUI
import SwiftlyKit

/// Strip-binary toggle and its contextual information button.
struct StripBinaryControl: View {

    @Binding var isEnabled: Bool
    @Binding var infoPopoverPresented: Bool

    var body: some View {
        HStack(spacing: Constants.configurationAccessorySpacing) {
            Toggle("Strip Binary", isOn: $isEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)

            ConfigurationInfoButton(
                isPresented: $infoPopoverPresented,
                option: .stripBinary
            )
        }
    }

}
