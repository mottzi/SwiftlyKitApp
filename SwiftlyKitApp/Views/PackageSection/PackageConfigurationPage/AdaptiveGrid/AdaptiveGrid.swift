import SwiftUI

/// Grid layout for alternating label and control subviews.
/// Uses the supplied arrangement, or fits columns automatically when none is supplied.
struct AdaptiveGrid: Layout {

    /// Optional displayed arrangement, allowing a parent to animate a measured column change.
    let arrangement: AdaptiveGridArrangement?

    /// Gap between a label and its control.
    let labelSpacing: CGFloat

    /// Gap between form columns.
    let columnSpacing: CGFloat

    /// Gap between form rows.
    let rowSpacing: CGFloat

    init(
        arrangement: AdaptiveGridArrangement? = nil,
        labelSpacing: CGFloat = Self.defaultLabelSpacing,
        columnSpacing: CGFloat = Self.defaultColumnSpacing,
        rowSpacing: CGFloat = Self.defaultRowSpacing
    ) {
        self.arrangement = arrangement
        self.labelSpacing = labelSpacing
        self.columnSpacing = columnSpacing
        self.rowSpacing = rowSpacing
    }

    /// Returns the form's size for a parent proposal.
    /// Uses the supplied arrangement, or fits columns automatically when none is supplied.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // Intrinsic/minimum-size probes must stay independent of the animated arrangement.
        // Otherwise a displayed two-column grid raises the window floor above its breakpoint.
        let isSizingProbe = proposal.width == nil || proposal.width == 0 || proposal.width == .infinity
        return layoutPlan(
            proposedWidth: proposal.width,
            measuresAutomaticArrangement: isSizingProbe,
            subviews: subviews
        )?.size ?? .zero
    }

    /// Places label-control fields in one or two columns based on the assigned width.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {

        guard bounds.width.isFinite, bounds.width > 0 else { return }
        guard let plan = layoutPlan(
            proposedWidth: bounds.width,
            exactFormWidth: bounds.width,
            subviews: subviews
        ) else { return }

        // Place the fields from left to right, advancing the row after each column.
        for fieldIndex in 0..<plan.fieldCount {
            let rowIndex = fieldIndex / plan.columnCount
            let columnIndex = fieldIndex % plan.columnCount
            placeField(
                fieldIndex,
                columnIndex: columnIndex,
                rowOriginY: bounds.minY + plan.rowOriginY(forFieldAt: fieldIndex),
                rowHeight: plan.rowHeights[rowIndex],
                in: bounds,
                columnCount: plan.columnCount,
                columnWidths: plan.columnWidths,
                columnMetrics: plan.columnMetrics,
                subviews: subviews
            )
        }
    }

    /// Exposes the one-column height without changing the grid's current arrangement or size.
    func explicitAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGFloat? {
        metricAlignment(
            of: guide,
            in: bounds,
            proposal: proposal,
            subviews: subviews
        )
    }

}

extension AdaptiveGrid {

    private static let defaultLabelSpacing: CGFloat = 12
    private static let defaultColumnSpacing: CGFloat = 24
    private static let defaultRowSpacing: CGFloat = 12

}
