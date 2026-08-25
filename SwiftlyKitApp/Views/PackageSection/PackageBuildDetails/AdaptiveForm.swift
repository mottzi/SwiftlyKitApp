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
        columnSpacing: CGFloat = 24,
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
        let width = resolvedWidth(
            idealWidth: idealWidth,
            proposedWidth: proposal.width,
            columnCount: columnCount
        )
        let columnMetrics = columnMetrics(for: columnCount, metrics: metrics)
        let columnWidths = columnWidths(
            layoutWidth: width,
            columnCount: columnCount,
            columnMetrics: columnMetrics
        )

        let rowHeights = rowHeights(
            columnCount: columnCount,
            columnWidths: columnWidths,
            columnMetrics: columnMetrics,
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
        let columnMetrics = columnMetrics(for: columnCount, metrics: metrics)
        let columnWidths = columnWidths(
            layoutWidth: bounds.width,
            columnCount: columnCount,
            columnMetrics: columnMetrics
        )

        let rowHeights = rowHeights(
            columnCount: columnCount,
            columnWidths: columnWidths,
            columnMetrics: columnMetrics,
            subviews: subviews
        )

        var rowOriginY = bounds.minY

        let fieldIndices = fieldIndices(for: subviews)

        for fieldIndex in fieldIndices {
            let row = fieldIndex / columnCount
            let column = fieldIndex % columnCount
            let columnOriginX = bounds.minX
                + columnWidths.prefix(column).reduce(0, +)
                + columnSpacing * CGFloat(column)
            let columnWidth = columnWidths[column]
            let labelIndex = fieldIndex * 2
            let controlIndex = labelIndex + 1
            let rowHeight = rowHeights[row]
            let labelWidth = min(
                columnMetrics[column].labelWidth,
                max(columnWidth - labelSpacing, 0)
            )
            let controlWidth = max(columnWidth - labelWidth - labelSpacing, 0)

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
                    ProposedViewSize(
                        width: columnCount == 1 ? nil : controlWidth,
                        height: nil
                    )
                )
                let leadingControlX = columnOriginX + labelWidth + labelSpacing
                let trailingControlX = columnOriginX + columnWidth - controlSize.width
                // Trailing-align one-column controls without allowing rigid content to overlap its label.
                let controlOriginX = columnCount == 1
                    ? max(leadingControlX, trailingControlX)
                    : leadingControlX
                let controlOrigin = CGPoint(
                    x: controlOriginX,
                    y: rowOriginY + (rowHeight - controlSize.height) / 2
                )

                subviews[controlIndex].place(
                    at: controlOrigin,
                    anchor: .topLeading,
                    proposal: ProposedViewSize(
                        width: columnCount == 1 ? controlSize.width : controlWidth,
                        height: controlSize.height
                    )
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
        let labelWidths: [CGFloat]
        let controlWidths: [CGFloat]
        let fieldCount: Int
    }

    struct ColumnMetrics {
        let labelWidth: CGFloat
        let controlWidth: CGFloat
    }

    func idealMetrics(for subviews: Subviews) -> Metrics {
        let fieldCount = (subviews.count + 1) / 2
        let labelWidths = (0..<fieldCount).map { fieldIndex in
            subviews[fieldIndex * 2].sizeThatFits(.unspecified).width
        }
        let controlWidths = (0..<fieldCount).map { fieldIndex in
            let controlIndex = fieldIndex * 2 + 1
            return controlIndex < subviews.count
                ? subviews[controlIndex].sizeThatFits(.unspecified).width
                : 0
        }

        return Metrics(
            labelWidths: labelWidths,
            controlWidths: controlWidths,
            fieldCount: fieldCount
        )
    }

    func columnMetrics(for columnCount: Int, metrics: Metrics) -> [ColumnMetrics] {
        guard columnCount > 0 else { return [] }

        return (0..<columnCount).map { column in
            let fieldIndices = stride(from: column, to: metrics.fieldCount, by: columnCount)
            return ColumnMetrics(
                labelWidth: fieldIndices.map { metrics.labelWidths[$0] }.max() ?? 0,
                controlWidth: fieldIndices.map { metrics.controlWidths[$0] }.max() ?? 0
            )
        }
    }

    func columnCount(for width: CGFloat?, metrics: Metrics) -> Int {
        guard metrics.fieldCount > 1 else { return metrics.fieldCount }
        guard let width else { return 1 }
        guard width.isFinite else { return 2 }

        return width >= layoutWidth(columnCount: 2, metrics: metrics) ? 2 : 1
    }

    func layoutWidth(columnCount: Int, metrics: Metrics) -> CGFloat {
        guard columnCount > 0 else { return 0 }

        let columnsWidth = columnMetrics(for: columnCount, metrics: metrics)
            .map { $0.labelWidth + labelSpacing + $0.controlWidth }
            .reduce(0, +)
        return columnsWidth + columnSpacing * CGFloat(columnCount - 1)
    }

    func resolvedWidth(
        idealWidth: CGFloat,
        proposedWidth: CGFloat?,
        columnCount: Int
    ) -> CGFloat {
        guard let proposedWidth, proposedWidth.isFinite else { return idealWidth }

        if columnCount == 1 {
            return max(proposedWidth, 0)
        }

        return min(max(proposedWidth, 0), idealWidth)
    }

    func columnWidths(
        layoutWidth: CGFloat,
        columnCount: Int,
        columnMetrics: [ColumnMetrics]
    ) -> [CGFloat] {
        guard columnCount > 0 else { return [] }

        if columnCount == 1 {
            return [max(layoutWidth, 0)]
        }

        return columnMetrics.map {
            max($0.labelWidth + labelSpacing + $0.controlWidth, 0)
        }
    }

    func rowHeights(
        columnCount: Int,
        columnWidths: [CGFloat],
        columnMetrics: [ColumnMetrics],
        subviews: Subviews
    ) -> [CGFloat] {
        guard columnCount > 0 else { return [] }

        let fieldIndices = fieldIndices(for: subviews)
        let rowCount = (fieldIndices.count + columnCount - 1) / columnCount
        var heights = Array(repeating: CGFloat.zero, count: rowCount)

        for fieldIndex in fieldIndices {
            let column = fieldIndex % columnCount
            let columnWidth = columnWidths[column]
            let labelWidth = min(
                columnMetrics[column].labelWidth,
                max(columnWidth - labelSpacing, 0)
            )
            let controlWidth = max(columnWidth - labelWidth - labelSpacing, 0)
            let labelIndex = fieldIndex * 2
            let controlIndex = labelIndex + 1
            let labelHeight = subviews[labelIndex].sizeThatFits(
                ProposedViewSize(width: labelWidth, height: nil)
            ).height
            let controlHeight = if controlIndex < subviews.count {
                subviews[controlIndex].sizeThatFits(
                    ProposedViewSize(
                        width: columnCount == 1 ? nil : controlWidth,
                        height: nil
                    )
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
