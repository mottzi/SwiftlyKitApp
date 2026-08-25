import SwiftUI

/// Form layout with alternating label and control subviews.
/// Uses two columns when their ideal widths fit, otherwise one.
struct AdaptiveForm: Layout {

    /// Distance between a label and its control.
    let labelSpacing: CGFloat

    /// Distance between form columns.
    let columnSpacing: CGFloat

    /// Distance between form rows.
    let rowSpacing: CGFloat

    init(
        labelSpacing: CGFloat = 12,
        columnSpacing: CGFloat = 0,
        rowSpacing: CGFloat = 12
    ) {
        self.labelSpacing = labelSpacing
        self.columnSpacing = columnSpacing
        self.rowSpacing = rowSpacing
    }

}

extension AdaptiveForm {

    /// Layout size based on the intrinsic label and control widths.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let metrics = idealMetrics(for: subviews)
        let columnCount = columnCount(for: proposal.width, metrics: metrics)
        let idealWidth = layoutWidth(columnCount: columnCount, metrics: metrics)
        let width = resolvedWidth(idealWidth: idealWidth, proposedWidth: proposal.width)
        let rowHeights = rowHeights(
            columnCount: columnCount,
            columnWidth: columnWidth(layoutWidth: width, columnCount: columnCount),
            labelWidth: metrics.labelWidth,
            subviews: subviews
        )

        return CGSize(
            width: width,
            height: rowHeights.reduce(0, +) + rowSpacing * CGFloat(max(rowHeights.count - 1, 0))
        )
    }

    /// Places each label-control pair in one or two form columns.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty, bounds.width.isFinite, bounds.width > 0 else { return }

        let metrics = idealMetrics(for: subviews)
        let columnCount = columnCount(for: bounds.width, metrics: metrics)
        let columnWidth = columnWidth(layoutWidth: bounds.width, columnCount: columnCount)
        let labelWidth = min(metrics.labelWidth, max(columnWidth - labelSpacing, 0))
        let controlWidth = max(columnWidth - labelWidth - labelSpacing, 0)
        let rowHeights = rowHeights(
            columnCount: columnCount,
            columnWidth: columnWidth,
            labelWidth: labelWidth,
            subviews: subviews
        )

        var rowOriginY = bounds.minY

        let fieldIndices = fieldIndices(for: subviews)

        for fieldIndex in fieldIndices {
            let row = fieldIndex / columnCount
            let column = fieldIndex % columnCount
            let columnOriginX = bounds.minX + CGFloat(column) * (columnWidth + columnSpacing)
            let labelIndex = fieldIndex * 2
            let controlIndex = labelIndex + 1
            let rowHeight = rowHeights[row]

            let labelSize = subviews[labelIndex].sizeThatFits(
                ProposedViewSize(width: labelWidth, height: nil)
            )
            let labelOrigin = CGPoint(
                x: columnOriginX,
                y: rowOriginY + (rowHeight - labelSize.height) / 2
            )

            subviews[labelIndex].place(
                at: labelOrigin,
                anchor: .topLeading,
                proposal: ProposedViewSize(width: labelWidth, height: labelSize.height)
            )

            if controlIndex < subviews.count {
                let controlSize = subviews[controlIndex].sizeThatFits(
                    ProposedViewSize(width: controlWidth, height: nil)
                )
                let controlOrigin = CGPoint(
                    x: columnOriginX + labelWidth + labelSpacing,
                    y: rowOriginY + (rowHeight - controlSize.height) / 2
                )

                subviews[controlIndex].place(
                    at: controlOrigin,
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: controlWidth, height: controlSize.height)
                )
            }

            if column == columnCount - 1 || fieldIndex == fieldIndices.last {
                rowOriginY += rowHeight + rowSpacing
            }
        }
    }

}

private extension AdaptiveForm {

    struct Metrics {
        let labelWidth: CGFloat
        let controlWidth: CGFloat
        let fieldCount: Int
    }

    func idealMetrics(for subviews: Subviews) -> Metrics {
        let labelWidths = subviews.indices
            .filter { $0.isMultiple(of: 2) }
            .map { subviews[$0].sizeThatFits(.unspecified).width }
        let controlWidths = subviews.indices
            .filter { !$0.isMultiple(of: 2) }
            .map { subviews[$0].sizeThatFits(.unspecified).width }

        return Metrics(
            labelWidth: labelWidths.max() ?? 0,
            controlWidth: controlWidths.max() ?? 0,
            fieldCount: (subviews.count + 1) / 2
        )
    }

    func columnCount(for width: CGFloat?, metrics: Metrics) -> Int {
        guard metrics.fieldCount > 1 else { return metrics.fieldCount }
        guard let width else { return 1 }
        guard width.isFinite else { return 2 }

        return width >= layoutWidth(columnCount: 2, metrics: metrics) ? 2 : 1
    }

    func layoutWidth(columnCount: Int, metrics: Metrics) -> CGFloat {
        guard columnCount > 0 else { return 0 }

        let fieldWidth = metrics.labelWidth + labelSpacing + metrics.controlWidth
        return fieldWidth * CGFloat(columnCount) + columnSpacing * CGFloat(columnCount - 1)
    }

    func resolvedWidth(idealWidth: CGFloat, proposedWidth: CGFloat?) -> CGFloat {
        guard let proposedWidth, proposedWidth.isFinite else { return idealWidth }

        return min(max(proposedWidth, 0), idealWidth)
    }

    func columnWidth(layoutWidth: CGFloat, columnCount: Int) -> CGFloat {
        guard columnCount > 0 else { return 0 }

        return max(
            (layoutWidth - columnSpacing * CGFloat(columnCount - 1)) / CGFloat(columnCount),
            0
        )
    }

    func rowHeights(
        columnCount: Int,
        columnWidth: CGFloat,
        labelWidth: CGFloat,
        subviews: Subviews
    ) -> [CGFloat] {
        guard columnCount > 0 else { return [] }

        let resolvedLabelWidth = min(labelWidth, max(columnWidth - labelSpacing, 0))
        let controlWidth = max(columnWidth - resolvedLabelWidth - labelSpacing, 0)
        let fieldIndices = fieldIndices(for: subviews)
        let rowCount = (fieldIndices.count + columnCount - 1) / columnCount
        var heights = Array(repeating: CGFloat.zero, count: rowCount)

        for fieldIndex in fieldIndices {
            let labelIndex = fieldIndex * 2
            let controlIndex = labelIndex + 1
            let labelHeight = subviews[labelIndex].sizeThatFits(
                ProposedViewSize(width: resolvedLabelWidth, height: nil)
            ).height
            let controlHeight = if controlIndex < subviews.count {
                subviews[controlIndex].sizeThatFits(
                    ProposedViewSize(width: controlWidth, height: nil)
                ).height
            } else {
                CGFloat.zero
            }
            let row = fieldIndex / columnCount

            heights[row] = max(heights[row], max(labelHeight, controlHeight))
        }

        return heights
    }

    func fieldIndices(for subviews: Subviews) -> Range<Int> {
        0..<((subviews.count + 1) / 2)
    }

}
