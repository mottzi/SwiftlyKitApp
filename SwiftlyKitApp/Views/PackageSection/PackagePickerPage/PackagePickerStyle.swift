import SwiftUI

/// Visual treatment for the package import affordance.
struct PackagePickerStyle: ButtonStyle {

    /// Keeps the interaction region, fill, and outline on the same rounded geometry.
    let shape = RoundedRectangle(cornerRadius: PackagePickerStyle.cornerRadius)

    /// Marks the import affordance as the current destination for a dragged package.
    let isDropTargeted: Bool

    /// Replaces the idle outline with active hover feedback while the picker can accept a package.
    let showsHover: Bool

    /// Keeps pressed and border feedback off after a package is selected.
    let canSelect: Bool

    /// Presents a dashed idle outline, active hover and press feedback, and a stronger drag-over state.
    func makeBody(configuration: Configuration) -> some View {

        let isPressed = canSelect && configuration.isPressed

        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.interaction, shape)
            .background { background(isPressed: isPressed) }
            .overlay { border(isDashed: true, isPressed: isPressed) }
            .overlay { border(isDashed: false, isPressed: isPressed) }
            .scaleEffect(isPressed ? Self.pressedScale : 1)
            .animation(.default, value: isDropTargeted)
            .animation(.default, value: showsHover)
            .animation(.default, value: isPressed)
    }

}

extension PackagePickerStyle {

    /// Draws the orange feedback layer for hover, press, and drag-over states.
    private func background(isPressed: Bool) -> some View {
        shape
            .fill(Color.orange.opacity(fillOpacity(isPressed: isPressed)))
    }

    /// Keeps the empty picker transparent and raises orange fill through hover, press, and drag-over feedback.
    private func fillOpacity(isPressed: Bool) -> Double {
        if isPressed {
            Self.pressedFillOpacity
        } else if isDropTargeted {
            Self.targetedFillOpacity
        } else if showsHover {
            Self.hoverFillOpacity
        } else {
            0
        }
    }

}

extension PackagePickerStyle {

    /// Draws the outline that represents the current phase of package selection.
    private func border(isDashed: Bool, isPressed: Bool) -> some View {
        shape
            .strokeBorder(
                borderColor(isPressed: isPressed),
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    dash: isDashed ? dashPattern : [],
                    dashPhase: isDashed ? dashPhase(isPressed: isPressed) : 0
                )
            )
            .opacity(isBorderVisible(isDashed: isDashed, isPressed: isPressed) ? 1 : 0)
    }

    /// Uses orange for hover and drag-over feedback, and secondary for the idle invitation.
    private func borderColor(isPressed: Bool) -> Color {
        isDropTargeted || showsHover || isPressed ? .orange : .secondary
    }

    /// Makes the drag-over outline visually distinct from the idle dashed invitation.
    private var dashPattern: [CGFloat] {
        isDropTargeted
            ? Self.targetedDashPattern
            : Self.idleDashPattern
    }

    /// Hides the outline after selection and thickens it to reinforce an active drop target.
    private var lineWidth: CGFloat {
        if !canSelect {
            0
        } else if isDropTargeted {
            Self.targetedLineWidth
        } else {
            Self.idleLineWidth
        }
    }

    /// Shifts the dashes as the outline animates into hover, press, or drag-over feedback.
    private func dashPhase(isPressed: Bool) -> CGFloat {
        if isDropTargeted {
            Self.activeDashPhase
        } else if showsHover {
            isPressed
                ? Self.activeDashPhase
                : Self.hoverDashPhase
        } else {
            0
        }
    }

}

private extension PackagePickerStyle {

    static let cornerRadius: CGFloat = 12
    static let pressedScale: CGFloat = 0.98
    static let pressedFillOpacity = 0.10
    static let targetedFillOpacity = 0.12
    static let hoverFillOpacity = 0.04
    static let idleDashPattern: [CGFloat] = [8, 6]
    static let targetedDashPattern: [CGFloat] = [10, 6]
    static let idleLineWidth: CGFloat = 2
    static let targetedLineWidth: CGFloat = 3
    static let hoverDashPhase: CGFloat = -6
    static let activeDashPhase: CGFloat = -12

}

extension PackagePickerStyle {

    /// Switches from the dashed idle invitation to a solid active outline, and hides both after selection.
    private func isBorderVisible(isDashed: Bool, isPressed: Bool) -> Bool {

        guard canSelect else { return false }

        return isDashed
            ? showsDashedBorder(isPressed: isPressed)
            : showsSolidBorder(isPressed: isPressed)
    }

    /// Keeps the dashed invitation at rest and during drag-over, but yields to the solid active outline on hover or press.
    private func showsDashedBorder(isPressed: Bool) -> Bool {
        isDropTargeted || !(showsHover || isPressed)
    }

    /// Shows the solid active outline on hover or press, unless drag-over takes priority.
    private func showsSolidBorder(isPressed: Bool) -> Bool {
        !isDropTargeted && (showsHover || isPressed)
    }

}
