import SwiftUI

/// Grid layout for alternating label and control subviews.
/// Uses two columns if the fields' ideal widths fit the proposed width.
struct LabelControlGrid: Layout {

    /// Gap between a label and its control.
    let labelSpacing: CGFloat

    /// Gap between form columns.
    let columnSpacing: CGFloat

    /// Gap between form rows.
    let rowSpacing: CGFloat

    init(
        labelSpacing: CGFloat = 12,
        columnSpacing: CGFloat = 24,
        rowSpacing: CGFloat = 12
    ) {
        self.labelSpacing = labelSpacing
        self.columnSpacing = columnSpacing
        self.rowSpacing = rowSpacing
    }

}

extension LabelControlGrid {

    /// Returns the form's size for a parent proposal.
    /// Uses two columns if the fields' ideal widths fit the proposed width.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {

        guard !subviews.isEmpty else { return .zero }

        // Measure each field at its ideal width and choose the number of columns.
        let idealWidths = idealFieldWidths(for: subviews)
        let columnCount = columnCount(for: proposal.width, idealWidths: idealWidths)

        let idealWidth = idealFormWidth(for: columnCount, idealWidths: idealWidths)
        let formWidth = resolvedFormWidth(idealWidth: idealWidth, proposedWidth: proposal.width, columnCount: columnCount)

        let columnMetrics = columnMetrics(for: columnCount, idealWidths: idealWidths)
        let columnWidths = columnWidths(formWidth: formWidth, columnCount: columnCount, columnMetrics: columnMetrics)
        let rowHeights = rowHeights(
            fieldCount: idealWidths.count,
            columnCount: columnCount,
            columnWidths: columnWidths,
            columnMetrics: columnMetrics,
            subviews: subviews
        )

        let contentHeight = rowHeights.reduce(0, +)
        let rowSpacingHeight = rowSpacing * CGFloat(max(rowHeights.count - 1, 0))

        return CGSize(width: formWidth, height: contentHeight + rowSpacingHeight)
    }

    /// Places label-control fields in one or two columns based on the assigned width.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {

        guard !subviews.isEmpty else { return }
        guard bounds.width.isFinite, bounds.width > 0 else { return }

        // Measure each field at its ideal width and choose the number of columns.
        let idealWidths = idealFieldWidths(for: subviews)
        let columnCount = columnCount(for: bounds.width, idealWidths: idealWidths)
        let columnMetrics = columnMetrics(for: columnCount, idealWidths: idealWidths)
        let columnWidths = columnWidths(formWidth: bounds.width, columnCount: columnCount, columnMetrics: columnMetrics)
        let rowHeights = rowHeights(
            fieldCount: idealWidths.count,
            columnCount: columnCount,
            columnWidths: columnWidths,
            columnMetrics: columnMetrics,
            subviews: subviews
        )

        // Place the fields from left to right, advancing the row after each column.
        var rowOriginY = bounds.minY
        for fieldIndex in 0..<idealWidths.count {
            let rowIndex = fieldIndex / columnCount
            let columnIndex = fieldIndex % columnCount
            placeField(
                fieldIndex,
                columnIndex: columnIndex,
                rowOriginY: rowOriginY,
                rowHeight: rowHeights[rowIndex],
                in: bounds,
                columnCount: columnCount,
                columnWidths: columnWidths,
                columnMetrics: columnMetrics,
                subviews: subviews
            )

            if columnIndex == columnCount - 1 || fieldIndex == idealWidths.count - 1 {
                rowOriginY += rowHeights[rowIndex] + rowSpacing
            }
        }
    }

}

extension LabelControlGrid {

    /// Returns ideal label and control widths for each field.
    private func idealFieldWidths(for subviews: Subviews) -> [LabelControlWidths] {
        
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
    private func columnCount(for proposedWidth: CGFloat?, idealWidths: [LabelControlWidths]) -> Int {

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
    private func idealFormWidth(for columnCount: Int, idealWidths: [LabelControlWidths]) -> CGFloat {

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
    private func resolvedFormWidth(idealWidth: CGFloat, proposedWidth: CGFloat?, columnCount: Int) -> CGFloat {

        guard let proposedWidth, proposedWidth.isFinite else { return idealWidth }

        if columnCount == 1 {
            return max(proposedWidth, 0)
        }

        return min(max(proposedWidth, 0), idealWidth)
    }

    /// Returns the maximum label and control width for each column.
    private func columnMetrics(for columnCount: Int, idealWidths: [LabelControlWidths]) -> [LabelControlWidths] {

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
    private func columnWidths(formWidth: CGFloat, columnCount: Int, columnMetrics: [LabelControlWidths]) -> [CGFloat] {

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
    private func rowHeights(
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

    /// Places one label-control field using the selected column and row metrics.
    private func placeField(
        _ fieldIndex: Int,
        columnIndex: Int,
        rowOriginY: CGFloat,
        rowHeight: CGFloat,
        in bounds: CGRect,
        columnCount: Int,
        columnWidths: [CGFloat],
        columnMetrics: [LabelControlWidths],
        subviews: Subviews
    ) {

        let precedingColumnsWidth = columnWidths.prefix(columnIndex).reduce(0, +)
        let columnSpacingWidth = columnSpacing * CGFloat(columnIndex)
        let columnOriginX = bounds.minX + precedingColumnsWidth + columnSpacingWidth
        let columnWidth = columnWidths[columnIndex]
        let widths = fieldWidths(for: columnIndex, columnWidths: columnWidths, columnMetrics: columnMetrics)
        let labelIndex = fieldIndex * 2
        let controlIndex = labelIndex + 1

        let labelProposal = ProposedViewSize(width: widths.label, height: nil)
        let labelSize = subviews[labelIndex].sizeThatFits(labelProposal)
        let labelOrigin = CGPoint(x: columnOriginX, y: rowOriginY + (rowHeight - labelSize.height) / 2)
        let labelPlacementProposal = ProposedViewSize(width: widths.label, height: labelSize.height)
        subviews[labelIndex].place(at: labelOrigin, anchor: .topLeading, proposal: labelPlacementProposal)

        guard controlIndex < subviews.count else { return }

        let controlProposalWidth: CGFloat?
        if columnCount == 1 {
            controlProposalWidth = nil
        } else {
            controlProposalWidth = widths.control
        }
        let controlProposal = ProposedViewSize(width: controlProposalWidth, height: nil)
        let controlSize = subviews[controlIndex].sizeThatFits(controlProposal)
        let leadingControlX = columnOriginX + widths.label + labelSpacing
        let trailingControlX = columnOriginX + columnWidth - controlSize.width
        let controlOriginX = if columnCount == 1 {
            max(leadingControlX, trailingControlX)
        } else {
            leadingControlX
        }
        let controlPlacementWidth: CGFloat
        if columnCount == 1 {
            controlPlacementWidth = controlSize.width
        } else {
            controlPlacementWidth = widths.control
        }
        let controlPlacementProposal = ProposedViewSize(width: controlPlacementWidth, height: controlSize.height)

        let controlOrigin = CGPoint(x: controlOriginX, y: rowOriginY + (rowHeight - controlSize.height) / 2)
        subviews[controlIndex].place(at: controlOrigin, anchor: .topLeading, proposal: controlPlacementProposal)
    }

    /// Splits a column between its label and control.
    private func fieldWidths(
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

    /// Widths needed to measure or place one label-control field.
    private struct LabelControlWidths {
        let label: CGFloat
        let control: CGFloat
    }

}
