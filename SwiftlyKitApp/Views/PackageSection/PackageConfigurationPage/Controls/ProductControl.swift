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
                allowsSelection: allowsSelection(for: discovery.state)
            )

            DiscoveryAccessory(
                infoPopoverPresented: $infoPopoverPresented,
                statusPopoverPresented: $statusPopoverPresented,
                option: .product,
                presentation: accessoryPresentation(for: discovery.state)
            ) {
                ProductDiscoveryStatus(
                    state: discovery.state,
                    onReviewInstallation: discovery.requestInstallationApproval,
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
            case .discovering(let detail, _):
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

    private func allowsSelection(for state: ProductDiscoveryState) -> Bool {
        if case .ready = state { return true }
        return false
    }

}

/// Executable-product choices, with a read-only value if only one product is ready.
private struct ProductPicker: View {

    @Binding var selectedProduct: ExecutableProduct?

    let products: [ExecutableProduct]
    let allowsSelection: Bool

    var body: some View {
        if allowsSelection, products.count == 1, let selectedProduct {
            picker
                .hidden()
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                .overlay(alignment: .leading) {
                    Text(selectedProduct.name)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .accessibilityLabel("Product")
                        .accessibilityValue(selectedProduct.name)
                }
        } else {
            picker
        }
    }

}

extension ProductPicker {

    private var picker: some View {
        Picker(selection: $selectedProduct) {
            ForEach(products, id: \.name) { product in
                Text(product.name)
                    .tag(product as ExecutableProduct?)
            }
        } label: {
            Text("Product")
        } currentValueLabel: {
            Text(selectedProduct?.name ?? "—")
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .disabled(!allowsSelection || products.count <= 1)
    }

}
