import SwiftUI

extension PackagePicker {

    struct PickerStyle: ButtonStyle {
        
        let isDropTargeted: Bool
        let showsHover: Bool
        let canSelect: Bool

        func makeBody(configuration: Configuration) -> some View {
            let isPressed = canSelect && configuration.isPressed

            configuration.label
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.interaction, .rect(cornerRadius: 12))
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(fillOpacity(isPressed: isPressed)))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isDropTargeted || showsHover ? .orange : .secondary,
                            style: StrokeStyle(
                                lineWidth: lineWidth,
                                dash: isDropTargeted ? [10, 6] : [8, 6],
                                dashPhase: dashPhase(isPressed: isPressed)
                            )
                        )
                        .opacity(canSelect ? 1 : 0)
                }
                .scaleEffect(isPressed ? 0.98 : 1)
                .animation(.default, value: isDropTargeted)
                .animation(.default, value: showsHover)
                .animation(.default, value: isPressed)
        }

        private var lineWidth: CGFloat {
            if !canSelect {
                0
            } else if isDropTargeted {
                3
            } else {
                2
            }
        }

        private func fillOpacity(isPressed: Bool) -> Double {
            if isPressed {
                0.10
            } else if isDropTargeted {
                0.12
            } else if showsHover {
                0.04
            } else {
                0
            }
        }

        private func dashPhase(isPressed: Bool) -> CGFloat {
            if isDropTargeted {
                -12
            } else if showsHover {
                isPressed ? -12 : -6
            } else {
                0
            }
        }
    }

}
