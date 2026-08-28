import SwiftUI

/// One configuration choice with its contextual information popover.
struct BuildOptionInfoButton: View {

    @Binding var isPresented: Bool
    let option: BuildOptionInfo

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "info.circle")
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .frame(
            width: ConfigurationAccessoryMetrics.length,
            height: ConfigurationAccessoryMetrics.length
        )
        .foregroundStyle(Color.secondary.opacity(ConfigurationAccessoryMetrics.opacity))
        .help(option.accessibilityLabel)
        .accessibilityLabel(option.accessibilityLabel)
        .popover(isPresented: $isPresented, arrowEdge: .trailing) {
            BuildOptionInfoPopover(option: option)
        }
    }

}
