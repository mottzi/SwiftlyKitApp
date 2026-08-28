import SwiftUI
import SwiftlyKit

/// Product selection and its fixed-width state-dependent accessory.
struct ProductControl: View {

    @Environment(BuildOptions.self) private var buildOptions

    @Binding var infoPopoverPresented: Bool
    @Binding var statusPopoverPresented: Bool

    let onRetry: () -> Void

    var body: some View {
        @Bindable var buildOptions = buildOptions

        HStack(spacing: Constants.configurationAccessorySpacing) {
            productPicker(
                selectedProduct: $buildOptions.selectedProduct,
                products: buildOptions.availableProducts,
                discoveryState: buildOptions.productDiscoveryState
            )

            Accessory(
                infoPopoverPresented: $infoPopoverPresented,
                statusPopoverPresented: $statusPopoverPresented,
                state: buildOptions.productDiscoveryState,
                onRetry: onRetry
            )
        }
        .onChange(of: buildOptions.productDiscoveryState) {
            reconcilePopovers(for: buildOptions.productDiscoveryState)
        }
    }

}

extension ProductControl {

    private func productPicker(
        selectedProduct: Binding<ExecutableProduct?>,
        products: [ExecutableProduct],
        discoveryState: ProductDiscoveryState
    ) -> some View {
        Picker("Product", selection: selectedProduct) {
            Text(pickerPlaceholder(for: discoveryState))
                .tag(nil as ExecutableProduct?)
            
            ForEach(products, id: \.name) { product in
                Text(product.name)
                    .tag(product as ExecutableProduct?)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .disabled(!allowsProductSelection(for: discoveryState))
    }

    private func pickerPlaceholder(for discoveryState: ProductDiscoveryState) -> String {
        switch discoveryState {
            case .idle: "—"
            case .discovering: "Discovering…"
            case .ready: "Choose Product"
            case .empty: "No Executables"
            case .failed: "Couldn’t Load"
        }
    }

    private func allowsProductSelection(for discoveryState: ProductDiscoveryState) -> Bool {
        if case .ready = discoveryState { return true }
        return false
    }

    private func reconcilePopovers(for state: ProductDiscoveryState) {

        switch state {
            case .idle, .ready:
                statusPopoverPresented = false
            case .discovering:
                infoPopoverPresented = false
                statusPopoverPresented = false
            case .empty, .failed:
                infoPopoverPresented = false
        }
    }

}
