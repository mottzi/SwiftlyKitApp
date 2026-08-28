import SwiftUI

/// One configuration choice with its contextual information popover.
struct ConfigurationInfoButton: View {

    @Binding var isPresented: Bool
    let option: ConfigurationOption

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "info.circle")
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .frame(
            width: Constants.configurationAccessoryLength,
            height: Constants.configurationAccessoryLength
        )
        .foregroundStyle(.secondary)
        .help(option.accessibilityLabel)
        .accessibilityLabel(option.accessibilityLabel)
        .popover(isPresented: $isPresented, arrowEdge: .trailing) {
            ConfigurationInfoPopover(option: option)
        }
    }

}
