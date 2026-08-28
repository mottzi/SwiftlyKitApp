import SwiftUI

/// Compact contextual explanation for the selected configuration choice.
struct BuildOptionInfoPopover: View {

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

private extension BuildOptionInfoPopover {

    static let width: CGFloat = 280

}
