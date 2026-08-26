import SwiftUI

extension PackagePicker {

    struct PickerLabel: View {

        let showsHover: Bool
        let isDropTargeted: Bool

        var body: some View {
            VStack(spacing: 16) {
                icon
                title
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding()
        }

    }

}

extension PackagePicker.PickerLabel {

    private var icon: some View {
        Image(systemName: "swift")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .rotationEffect(showsHover && !isDropTargeted ? .degrees(4) : .zero)
            .scaleEffect(isDropTargeted ? 1.10 : 1)
            .foregroundStyle(isDropTargeted || showsHover ? .orange : .secondary)
    }

    private var title: some View {
        Text("Select Package")
            .lineLimit(1)
            .truncationMode(.middle)
            .font(.title)
            // Keep the label's measured width stable while the drop target state changes.
            .fontWeight(.light)
            .foregroundStyle(isDropTargeted ? .orange : (showsHover ? .primary : .secondary))
    }

}
