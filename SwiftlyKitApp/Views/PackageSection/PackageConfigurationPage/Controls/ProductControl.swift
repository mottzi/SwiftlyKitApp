import SwiftUI
import SwiftlyKit

/// Product selection and its state-dependent discovery feedback.
struct ProductControl: View {

    @Environment(BuildOptions.self) private var buildOptions

    @Binding var infoPopoverPresented: Bool
    @Binding var statusPopoverPresented: Bool

    let onRetry: () -> Void

    var body: some View {
        @Bindable var discovery = buildOptions.productDiscovery

        HStack(spacing: ConfigurationAccessoryMetrics.spacing) {
            ProductPicker(
                selectedProduct: $discovery.selectedProduct,
                products: discovery.availableProducts,
                discoveryState: discovery.state
            )

            DiscoveryAccessory(
                infoPopoverPresented: $infoPopoverPresented,
                statusPopoverPresented: $statusPopoverPresented,
                option: .product,
                presentation: accessoryPresentation(for: discovery.state)
            ) {
                ProductDiscoveryStatusContent(
                    state: discovery.state,
                    onRetry: onRetry
                )
            }
        }
    }

    private func accessoryPresentation(
        for state: ProductDiscoveryState
    ) -> DiscoveryAccessoryPresentation {
        switch state {
            case .idle, .ready:
                return .information
            case .discovering(let detail):
                return .progress(accessibilityLabel: detail)
            case .installationRequired:
                return .status(
                    DiscoveryAccessoryPresentation.Status(
                        symbol: "arrow.down.circle",
                        color: .secondary,
                        label: "Swift components required"
                    )
                )
            case .empty:
                return .status(
                    DiscoveryAccessoryPresentation.Status(
                        symbol: "info.circle",
                        color: .secondary,
                        label: "No executable products"
                    )
                )
            case .failed:
                return .status(
                    DiscoveryAccessoryPresentation.Status(
                        symbol: "exclamationmark.triangle",
                        color: .orange,
                        label: "Product discovery failed"
                    )
                )
        }
    }

}

/// Executable-product picker with placeholders for each discovery state.
private struct ProductPicker: View {

    @Binding var selectedProduct: ExecutableProduct?

    let products: [ExecutableProduct]
    let discoveryState: ProductDiscoveryState

    var body: some View {
        Picker(selection: $selectedProduct) {
            ForEach(products, id: \.name) { product in
                Text(product.name)
                    .tag(product as ExecutableProduct?)
            }
        } label: {
            Text("Product")
        } currentValueLabel: {
            Text(selectedProduct?.name ?? placeholder)
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .disabled(!allowsSelection || products.count <= 1)
    }

    private var placeholder: String {
        switch discoveryState {
            case .idle, .discovering: "—"
            case .installationRequired: "Installation Required"
            case .ready: "Choose Product"
            case .empty: "No Executables"
            case .failed: "Couldn’t Load"
        }
    }

    private var allowsSelection: Bool {
        if case .ready = discoveryState { return true }
        return false
    }

}

/// Contextual explanation for a product discovery status.
private struct ProductDiscoveryStatusContent: View {

    let state: ProductDiscoveryState
    let onRetry: () -> Void

    var body: some View {
        switch state {
            case .installationRequired(let approval):
                VStack(alignment: .leading, spacing: 12) {
                    Text("Swift components required")
                        .font(.headline)

                    Text(approval.message)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Review Installation…", action: onRetry)
                        .keyboardShortcut(.defaultAction)
                }

            case .empty:
                EmptyDiscoveryStatus(
                    title: "No executable products",
                    message: "SwiftPM inspected this package but found no executable products.",
                    onRetry: onRetry
                )

            case .failed(let error):
                FailedDiscoveryStatus(
                    title: "Couldn’t discover executable products.",
                    detail: error.errorDescription ?? error.localizedDescription,
                    onRetry: onRetry
                )

            case .idle, .discovering, .ready:
                EmptyView()
        }
    }

}
