import SwiftUI

/// Current detail for an active discovery operation.
struct DiscoveryProgressStatus: View {

    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            Text(detail)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

}
