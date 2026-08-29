import SwiftUI

/// Explanation and retry action for an empty discovery result.
struct EmptyDiscoveryStatus: View {

    let title: String
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            Text(message)
                .fixedSize(horizontal: false, vertical: true)

            Button("Retry", action: onRetry)
                .keyboardShortcut(.defaultAction)
        }
    }

}
