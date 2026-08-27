import SwiftUI

extension PackagePicker {

    struct PickerLabel: View {

        let showsHover: Bool
        let isDropTargeted: Bool

        var body: some View {
            HStack(spacing: Constants.pickerLabelSpacing) {
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
            .frame(
                width: Constants.pickerIconLength,
                height: Constants.pickerIconLength
            )
            .rotationEffect(showsHover && !isDropTargeted ? Constants.pickerHoverRotation : .zero)
            .scaleEffect(isDropTargeted ? Constants.pickerTargetedScale : 1)
            .foregroundStyle(isDropTargeted || showsHover ? .orange : .secondary)
    }

    private var title: some View {
        Text("Select Package")
            .lineLimit(Constants.pickerTitleLineLimit)
            .truncationMode(.middle)
            .font(.title)
            // Keep the label's measured width stable while the drop target state changes.
            .fontWeight(.light)
            .foregroundStyle(isDropTargeted ? .orange : (showsHover ? .primary : .secondary))
    }

}
