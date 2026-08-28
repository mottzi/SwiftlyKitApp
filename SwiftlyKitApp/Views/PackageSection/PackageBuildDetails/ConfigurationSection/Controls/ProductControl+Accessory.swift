import SwiftUI
import SwiftlyKit

extension ProductControl {

    /// One fixed Product accessory that changes meaning with discovery state.
    struct Accessory: View {

        @Binding var infoPopoverPresented: Bool
        @Binding var statusPopoverPresented: Bool
        let state: ProductDiscoveryState
        let onRetry: () -> Void

        var body: some View {
            content
                .frame(
                    width: Constants.configurationAccessoryLength,
                    height: Constants.configurationAccessoryLength
                )
        }

        @ViewBuilder
        private var content: some View {
            switch state {
                case .idle, .ready:
                    ConfigurationInfoButton(
                        isPresented: $infoPopoverPresented,
                        option: .product
                    )

                case .discovering:
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("Discovering executable products")

                case .empty, .failed:
                    DiscoveryStatusButton(
                        isPresented: $statusPopoverPresented,
                        state: state,
                        onRetry: onRetry
                    )
            }
        }

        /// Product discovery status button with an anchored explanation popover.
        private struct DiscoveryStatusButton: View {

            @Binding var isPresented: Bool
            let state: ProductDiscoveryState
            let onRetry: () -> Void

            var body: some View {
                Button {
                    isPresented = true
                } label: {
                    Image(systemName: statusSymbol)
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .foregroundStyle(statusColor)
                .help(statusLabel)
                .accessibilityLabel(statusLabel)
                .popover(isPresented: $isPresented, arrowEdge: .trailing) {
                    DiscoveryStatusPopover(state: state, onRetry: onRetry)
                }
            }

            private var statusSymbol: String {
                if case .failed = state { return "exclamationmark.triangle" }
                return "info.circle"
            }

            private var statusColor: Color {
                if case .failed = state { return .orange }
                return .secondary
            }

            private var statusLabel: String {
                if case .failed = state { return "Product discovery failed" }
                return "No executable products"
            }

        }

        /// Contextual explanation and retry controls for a failed or empty discovery.
        private struct DiscoveryStatusPopover: View {

            @State private var detailsExpanded = false

            let state: ProductDiscoveryState
            let onRetry: () -> Void

            var body: some View {
                content
                    .padding()
                    .frame(width: Constants.productDiscoveryPopoverWidth, alignment: .leading)
            }

            @ViewBuilder
            private var content: some View {
                switch state {
                    case .empty:
                        VStack(alignment: .leading, spacing: 12) {
                            Text("No executable products")
                                .font(.headline)

                            Text("SwiftPM inspected this package but found no executable products.")
                                .fixedSize(horizontal: false, vertical: true)

                            Button("Retry", action: onRetry)
                                .keyboardShortcut(.defaultAction)
                        }

                    case .failed(let error):
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Couldn’t discover executable products.")
                                .font(.headline)

                            Button("Retry", action: onRetry)
                                .keyboardShortcut(.defaultAction)

                            DisclosureGroup("Details", isExpanded: $detailsExpanded) {
                                Text(error.errorDescription ?? error.localizedDescription)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                                    .padding(.top, 4)
                            }
                        }

                    case .idle, .discovering, .ready:
                        EmptyView()
                }
            }

        }

    }

}
