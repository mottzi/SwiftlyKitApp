import SwiftUI

struct PackagePickerLabel: View {

    let showsHover: Bool
    let isDropTargeted: Bool
    let layoutMode: PackageSectionLayoutMode

    var body: some View {
        labelLayout {
            icon
            title
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding()
        .animation(.bouncy.speed(Self.layoutTransitionSpeed), value: layoutMode)
    }

}

extension PackagePickerLabel {

    private var labelLayout: AnyLayout {
        switch layoutMode {
            case .oneColumn: AnyLayout(VStackLayout(spacing: Self.verticalSpacing))
            case .twoColumns: AnyLayout(HStackLayout(spacing: Self.horizontalSpacing))
        }
    }

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

    private static let horizontalSpacing: CGFloat = 16
    private static let verticalSpacing: CGFloat = 12
    private static let layoutTransitionSpeed = 1.25
    private static let iconLength: CGFloat = 80
    private static let titleLineLimit = 1
    private static let hoverRotation = Angle.degrees(4)
    private static let targetedScale: CGFloat = 1.10

}
