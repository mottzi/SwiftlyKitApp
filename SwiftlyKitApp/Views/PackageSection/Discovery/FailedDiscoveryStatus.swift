import SwiftUI

/// Explanation, retry action, and diagnostic detail for a failed discovery.
struct FailedDiscoveryStatus: View {

    @State private var detailsExpanded = false

    let title: String
    let detail: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            Button("Retry", action: onRetry)
                .keyboardShortcut(.defaultAction)

            DisclosureGroup("Details", isExpanded: $detailsExpanded) {
                Text(detail)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                    .padding(.top, 4)
            }
        }
    }

}
