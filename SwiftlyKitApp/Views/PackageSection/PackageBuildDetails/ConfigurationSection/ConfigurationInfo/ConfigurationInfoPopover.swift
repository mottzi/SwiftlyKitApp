import SwiftUI

/// Compact contextual explanation for the selected configuration choice.
struct ConfigurationInfoPopover: View {

    let option: ConfigurationOption

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(option.title)
                .font(.headline)

            Text(option.message)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(width: Constants.configurationInfoPopoverWidth, alignment: .leading)
    }

}
