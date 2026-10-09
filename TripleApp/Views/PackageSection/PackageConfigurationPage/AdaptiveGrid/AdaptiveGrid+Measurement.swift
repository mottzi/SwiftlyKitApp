import SwiftUI

extension AdaptiveGrid {

    /// Returns ideal label and control widths for each field.
    func idealFieldWidths(for subviews: Subviews) -> [LabelControlWidths] {

        var idealWidths: [LabelControlWidths] = []

        // Measure each label-control pair at its ideal width.
        for labelIndex in stride(from: 0, to: subviews.count, by: 2) {
            let controlIndex = labelIndex + 1

            let labelWidth = subviews[labelIndex].sizeThatFits(.unspecified).width

            let controlWidth = if controlIndex < subviews.count {
                subviews[controlIndex].sizeThatFits(.unspecified).width
            } else {
                CGFloat.zero
            }

            idealWidths.append(LabelControlWidths(label: labelWidth, control: controlWidth))
        }

        return idealWidths
    }

    /// Chooses the number of columns from the proposed width and ideal field widths.
    func columnCount(for proposedWidth: CGFloat?, idealWidths: [LabelControlWidths]) -> Int {

        guard idealWidths.count > 1 else { return idealWidths.count }
        guard let proposedWidth else { return 1 }
        guard proposedWidth.isFinite else { return 2 }

        let fitsTwoColumns = proposedWidth >= idealFormWidth(for: 2, idealWidths: idealWidths)

        return if fitsTwoColumns {
            2
        } else {
            1
        }
    }

    /// Returns the width needed to fit the ideal fields in the given number of columns.
    func idealFormWidth(for columnCount: Int, idealWidths: [LabelControlWidths]) -> CGFloat {

        guard columnCount > 0 else { return 0 }

        let metrics = columnMetrics(for: columnCount, idealWidths: idealWidths)
        var totalColumnWidth = CGFloat.zero

        for metric in metrics {
            totalColumnWidth += metric.label + labelSpacing + metric.control
        }

        return totalColumnWidth + columnSpacing * CGFloat(columnCount - 1)
    }

    /// Resolves the form width from the parent proposal.
    /// A one-column form can expand to the proposal; two columns stop at their ideal width.
    func resolvedFormWidth(idealWidth: CGFloat, proposedWidth: CGFloat?, columnCount: Int) -> CGFloat {

        guard let proposedWidth, proposedWidth.isFinite else { return idealWidth }

        if columnCount == 1 {
            return max(proposedWidth, 0)
        }

        return min(max(proposedWidth, 0), idealWidth)
    }

    /// Returns the maximum label and control width for each column.
    func columnMetrics(for columnCount: Int, idealWidths: [LabelControlWidths]) -> [LabelControlWidths] {

        guard columnCount > 0 else { return [] }

        var metrics = [LabelControlWidths]()

        // Gather the widest label and control assigned to each column.
        for columnIndex in 0..<columnCount {
            let firstWidths = idealWidths[columnIndex]
            var labelWidth = firstWidths.label
            var controlWidth = firstWidths.control

            for fieldIndex in stride(from: columnIndex + columnCount, to: idealWidths.count, by: columnCount) {
                let widths = idealWidths[fieldIndex]
                labelWidth = max(labelWidth, widths.label)
                controlWidth = max(controlWidth, widths.control)
            }

            metrics.append(LabelControlWidths(label: labelWidth, control: controlWidth))
        }

        return metrics
    }

    /// Returns the width for each selected column.
    /// One column fills the form; two columns keep their ideal widths.
    func columnWidths(formWidth: CGFloat, columnCount: Int, columnMetrics: [LabelControlWidths]) -> [CGFloat] {

        guard columnCount > 0 else { return [] }

        if columnCount == 1 {
            return [max(formWidth, 0)]
        }

        var widths = [CGFloat]()

        for metric in columnMetrics {
            widths.append(max(metric.label + labelSpacing + metric.control, 0))
        }

        return widths
    }

    /// Returns the height required by each row at the assigned column widths.
    func rowHeights(
        fieldCount: Int,
        columnCount: Int,
        columnWidths: [CGFloat],
        columnMetrics: [LabelControlWidths],
        subviews: Subviews
    ) -> [CGFloat] {

        guard columnCount > 0 else { return [] }

        let rowCount = (fieldCount + columnCount - 1) / columnCount
        var rowHeights = Array(repeating: CGFloat.zero, count: rowCount)

        // Measure each field using the widths assigned to its column.
        for fieldIndex in 0..<fieldCount {
            let rowIndex = fieldIndex / columnCount
            let columnIndex = fieldIndex % columnCount
            let widths = fieldWidths(for: columnIndex, columnWidths: columnWidths, columnMetrics: columnMetrics)
            let labelIndex = fieldIndex * 2
            let controlIndex = labelIndex + 1
            let controlWidth: CGFloat?
            if columnCount == 1 {
                controlWidth = nil
            } else {
                controlWidth = widths.control
            }
            let labelProposal = ProposedViewSize(width: widths.label, height: nil)
            let labelSize = subviews[labelIndex].sizeThatFits(labelProposal)
            var controlSize = CGSize.zero
            if controlIndex < subviews.count {
                let controlProposal = ProposedViewSize(width: controlWidth, height: nil)
                controlSize = subviews[controlIndex].sizeThatFits(controlProposal)
            }
            rowHeights[rowIndex] = max(rowHeights[rowIndex], max(labelSize.height, controlSize.height))
        }

        return rowHeights
    }

    /// Splits a column between its label and control.
    func fieldWidths(
        for columnIndex: Int,
        columnWidths: [CGFloat],
        columnMetrics: [LabelControlWidths]
    ) -> LabelControlWidths {

        let columnWidth = columnWidths[columnIndex]
        let metric = columnMetrics[columnIndex]
        let labelWidth = min(metric.label, max(columnWidth - labelSpacing, 0))
        let controlWidth = max(columnWidth - labelWidth - labelSpacing, 0)

        return LabelControlWidths(label: labelWidth, control: controlWidth)
    }

}

extension AdaptiveGrid {

    /// Widths needed to measure or place one label-control field.
    struct LabelControlWidths {
        let label: CGFloat
        let control: CGFloat
    }

}
