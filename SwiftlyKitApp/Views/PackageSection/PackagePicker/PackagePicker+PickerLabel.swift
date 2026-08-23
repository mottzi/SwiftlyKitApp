import SwiftUI

extension PackagePicker {

    struct PickerLabel: View {
        
        let showsHover: Bool
        let isDropTargeted: Bool

        var body: some View {
            HStack(spacing: 16) {
                icon
                title
            }
        }

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
            ZStack(alignment: .leading) {
                Text("Drop Package here").hidden()
                Text("Select Package").hidden()
                Text("Drop to Select").hidden()
                Text(showsHover ? "Select Package" : "Drop Package here")
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .font(.largeTitle)
            .fontWeight(isDropTargeted ? .medium : .light)
            .foregroundStyle(isDropTargeted ? .orange : (showsHover ? .primary : .secondary))
        }
        
    }

}
