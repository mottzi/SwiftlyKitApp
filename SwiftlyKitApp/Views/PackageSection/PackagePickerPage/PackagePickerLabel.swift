import SwiftUI

struct PackagePickerLabel: View {

    let showsHover: Bool
    let isDropTargeted: Bool

    var body: some View {
        HStack(spacing: Self.labelSpacing) {
            icon
            title
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding()
    }

}

extension PackagePickerLabel {

    private var icon: some View {
        Image(systemName: "swift")
            .resizable()
            .scaledToFit()
            .frame(
                width: Self.iconLength,
                height: Self.iconLength
            )
            .rotationEffect(showsHover && !isDropTargeted ? Self.hoverRotation : .zero)
            .scaleEffect(isDropTargeted ? Self.targetedScale : 1)
            .foregroundStyle(isDropTargeted || showsHover ? .orange : .secondary)
    }

    private var title: some View {
        Text("Select Package")
            .lineLimit(Self.titleLineLimit)
            .truncationMode(.middle)
            .font(.title)
            // Keep the label's measured width stable while the drop target state changes.
            .fontWeight(.light)
            .foregroundStyle(isDropTargeted ? .orange : (showsHover ? .primary : .secondary))
    }

}

extension PackagePickerLabel {

    private static let labelSpacing: CGFloat = 16
    private static let iconLength: CGFloat = 80
    private static let titleLineLimit = 1
    private static let hoverRotation = Angle.degrees(4)
    private static let targetedScale: CGFloat = 1.10

}
