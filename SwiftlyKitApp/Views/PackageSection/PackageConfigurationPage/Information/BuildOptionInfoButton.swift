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

/// Compact contextual explanation for the selected configuration choice.
private struct BuildOptionInfoPopover: View {

    let option: BuildOptionInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(option.title)
                .font(.headline)

            Text(option.message)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(width: Self.width, alignment: .leading)
    }

}

extension BuildOptionInfoPopover {

    private static let width: CGFloat = 280

}
