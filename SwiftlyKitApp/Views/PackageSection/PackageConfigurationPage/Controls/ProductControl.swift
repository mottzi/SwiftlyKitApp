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

        HStack(spacing: ConfigurationAccessoryMetrics.spacing) {
            productPicker(
                selectedProduct: $buildOptions.selectedProduct,
                products: buildOptions.availableProducts,
                discoveryState: buildOptions.productDiscoveryState
            )

            ProductDiscoveryIndicator(
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

/// Fixed-width product discovery feedback shown beside the product picker.
private struct ProductDiscoveryIndicator: View {

    @Binding var infoPopoverPresented: Bool
    @Binding var statusPopoverPresented: Bool

    let state: ProductDiscoveryState
    let onRetry: () -> Void

    var body: some View {
        content
            .frame(
                width: ConfigurationAccessoryMetrics.length,
                height: ConfigurationAccessoryMetrics.length
            )
    }

    @ViewBuilder
    private var content: some View {
        switch state {
            case .idle, .ready:
                BuildOptionInfoButton(
                    isPresented: $infoPopoverPresented,
                    option: .product
                )

            case .discovering:
                ProductDiscoverySpinner()

            case .empty, .failed:
                ProductDiscoveryStatusButton(
                    isPresented: $statusPopoverPresented,
                    state: state,
                    onRetry: onRetry
                )
        }
    }

}

/// Indeterminate progress shown while SwiftlyKit discovers executable products.
struct ProductDiscoverySpinner: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isRotating = false

    var body: some View {
        Circle()
            .trim(from: 0.15, to: 0.85)
            .stroke(
                .secondary,
                style: StrokeStyle(
                    lineWidth: Self.lineWidth,
                    lineCap: .round
                )
            )
            .frame(
                width: Self.length,
                height: Self.length
            )
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(spinnerAnimation, value: isRotating)
            .onAppear {
                isRotating = !reduceMotion
            }
            .onChange(of: reduceMotion) {
                isRotating = !reduceMotion
            }
            .accessibilityElement()
            .accessibilityLabel("Discovering executable products")
            .accessibilityValue("In progress")
    }

    private var spinnerAnimation: Animation? {
        guard !reduceMotion else { return nil }

        return .linear(duration: Self.duration)
            .repeatForever(autoreverses: false)
    }

}

/// Product discovery status button with an anchored explanation popover.
private struct ProductDiscoveryStatusButton: View {

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
            ProductDiscoveryStatusPopover(state: state, onRetry: onRetry)
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
private struct ProductDiscoveryStatusPopover: View {

    @State private var detailsExpanded = false

    let state: ProductDiscoveryState
    let onRetry: () -> Void

    var body: some View {
        content
            .padding()
            .frame(width: Self.popoverWidth, alignment: .leading)
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

private extension ProductDiscoverySpinner {

    static let length: CGFloat = 14
    static let lineWidth: CGFloat = 2
    static let duration = 0.8

}

private extension ProductDiscoveryStatusPopover {

    static let popoverWidth: CGFloat = 320

}

extension ProductControl {

    private func productPicker(
        selectedProduct: Binding<ExecutableProduct?>,
        products: [ExecutableProduct],
        discoveryState: ProductDiscoveryState
    ) -> some View {
        Picker(selection: selectedProduct) {
            ForEach(products, id: \.name) { product in
                Text(product.name)
                    .tag(product as ExecutableProduct?)
            }
        } label: {
            Text("Product")
        } currentValueLabel: {
            Text(selectedProduct.wrappedValue?.name ?? pickerPlaceholder(for: discoveryState))
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
