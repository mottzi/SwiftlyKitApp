import SwiftUI

/// Contextual explanation for a product discovery status.
struct ProductDiscoveryStatus: View {

    let state: ProductDiscoveryState
    let onReviewInstallation: () -> Void
    let onRetry: () -> Void

    var body: some View {
        switch state {
            case .discovering(let detail):
                DiscoveryProgressStatus(
                    title: "Discovering executable products",
                    detail: detail
                )

            case .installationRequired(let approval):
                VStack(alignment: .leading, spacing: 12) {
                    Text("Swift components required")
                        .font(.headline)

                    Text(approval.message)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Review Installation…", action: onReviewInstallation)
                        .keyboardShortcut(.defaultAction)
                }

            case .empty:
                VStack(alignment: .leading, spacing: 12) {
                    Text("No executable products")
                        .font(.headline)

                    Text("Add an executable product to this package's manifest to build it.")
                        .fixedSize(horizontal: false, vertical: true)
                }

            case .failed(let error):
                FailedDiscoveryStatus(
                    title: "Couldn’t discover executable products.",
                    detail: error.errorDescription ?? error.localizedDescription,
                    onRetry: onRetry
                )

            case .idle, .ready:
                EmptyView()
        }
    }

}
