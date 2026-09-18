import SwiftUI

extension AdaptiveGrid {

    /// Builds one proposal-specific plan shared by measurement, placement, and metric reporting.
    func layoutPlan(
        proposedWidth: CGFloat?,
        exactFormWidth: CGFloat? = nil,
        measuresAutomaticArrangement: Bool = false,
        subviews: Subviews
    ) -> LayoutPlan? {
        guard !subviews.isEmpty else { return nil }

        let idealWidths = idealFieldWidths(for: subviews)
        let columnCount: Int
        if !measuresAutomaticArrangement, let arrangement {
            switch arrangement {
            case .oneColumn: columnCount = min(idealWidths.count, 1)
            case .twoColumns: columnCount = min(idealWidths.count, 2)
            }
        } else {
            columnCount = self.columnCount(for: proposedWidth, idealWidths: idealWidths)
        }
        let idealWidth = idealFormWidth(
            for: columnCount,
            idealWidths: idealWidths
        )
        let formWidth = exactFormWidth ?? resolvedFormWidth(
            idealWidth: idealWidth,
            proposedWidth: proposedWidth,
            columnCount: columnCount
        )
        let columnMetrics = columnMetrics(
            for: columnCount,
            idealWidths: idealWidths
        )
        let columnWidths = columnWidths(
            formWidth: formWidth,
            columnCount: columnCount,
            columnMetrics: columnMetrics
        )
        let rowHeights = rowHeights(
            fieldCount: idealWidths.count,
            columnCount: columnCount,
            columnWidths: columnWidths,
            columnMetrics: columnMetrics,
            subviews: subviews
        )

        return LayoutPlan(
            fieldCount: idealWidths.count,
            columnCount: columnCount,
            formWidth: formWidth,
            columnMetrics: columnMetrics,
            columnWidths: columnWidths,
            rowHeights: rowHeights,
            rowSpacing: rowSpacing
        )
    }

    /// Proposal-specific values used by every layout path.
    nonisolated struct LayoutPlan {

        let fieldCount: Int
        let columnCount: Int
        let formWidth: CGFloat
        let columnMetrics: [LabelControlWidths]
        let columnWidths: [CGFloat]
        let rowHeights: [CGFloat]
        let rowSpacing: CGFloat

        var size: CGSize {
            CGSize(width: formWidth, height: height)
        }

        var height: CGFloat {
            rowHeights.reduce(0, +)
                + rowSpacing * CGFloat(max(rowHeights.count - 1, 0))
        }

        func rowOriginY(forFieldAt fieldIndex: Int) -> CGFloat {
            let rowIndex = fieldIndex / columnCount
            return rowHeights.prefix(rowIndex).reduce(0, +)
                + rowSpacing * CGFloat(rowIndex)
        }

    }

}
