import SwiftUI

extension AdaptiveGrid {

    /// Places one label-control field using the selected column and row metrics.
    func placeField(
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

}
