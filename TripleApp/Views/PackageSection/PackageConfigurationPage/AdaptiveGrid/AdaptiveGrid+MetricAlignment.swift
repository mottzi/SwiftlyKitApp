import SwiftUI

extension AdaptiveGrid {

    /// Reports the grid coordinates used by the metric transport layer.
    func metricAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> CGFloat? {

        if guide == .adaptiveGridOneColumnBottom {
            let oneColumnPlan = layoutPlan(
                proposedWidth: nil,
                measuresAutomaticArrangement: true,
                subviews: subviews
            )
            return oneColumnPlan.map { bounds.minY + $0.height }
        }

        // Report the width-driven destination, even while the displayed arrangement is transitioning.
        guard guide == .adaptiveGridFirstFieldRow
                || guide == .adaptiveGridSecondFieldRow else { return nil }
        guard let currentPlan = layoutPlan(
            proposedWidth: bounds.width,
            exactFormWidth: bounds.width,
            measuresAutomaticArrangement: true,
            subviews: subviews
        ) else { return nil }

        let fieldIndex = guide == .adaptiveGridFirstFieldRow ? 0 : 1
        guard fieldIndex < currentPlan.fieldCount else { return nil }

        return bounds.minY + currentPlan.rowOriginY(forFieldAt: fieldIndex)
    }

}
