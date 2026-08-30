import SwiftUI

/// Horizontal pager that presents one selected page with an optional trailing reveal of the next.
/// Progress shifts the page row to show the selected page.
struct PagingHStack {

    /// Gap between adjacent pages.
    private let spacing: CGFloat

    /// Amount by which each nonfinal page is narrower than the pager viewport.
    private let pageTrailingInset: CGFloat

    /// Page index. 0 is the first page. A fraction is a position between pages.
    private var progress: CGFloat

    init(
        spacing: CGFloat,
        pageTrailingInset: CGFloat = 0,
        selection: Int
    ) {
        self.spacing = spacing
        self.pageTrailingInset = pageTrailingInset
        self.progress = CGFloat(selection)
    }

    init(
        spacing: CGFloat,
        pageTrailingInset: CGFloat = 0,
        selection: some RawRepresentable<Int>
    ) {
        self.init(
            spacing: spacing,
            pageTrailingInset: pageTrailingInset,
            selection: selection.rawValue
        )
    }

}

nonisolated extension PagingHStack: Layout {

    /// Interpolates `progress` during page transitions.
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    /// Returns the pager's size for a parent proposal, with variable page widths and enough intrinsic height by default.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {

        let viewportWidth = concreteViewportWidth(from: proposal.width)
        let pageSizes = measuredPageSizes(in: viewportWidth, subviews: subviews)
        let width = resolvedPagerWidth(
            for: proposal.width,
            viewportWidth: viewportWidth,
            pageSizes: pageSizes
        )
        let idealHeight = pageSizes.map(\.height).max() ?? 0
        let height = resolvedPagerHeight(
            for: proposal.height,
            idealHeight: idealHeight
        )

        return CGSize(width: width, height: height)
    }

    /// Places nonfinal pages at their reduced width and the final page at the full viewport width.
    /// Progress shifts the row by the nonfinal page width plus spacing.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {

        guard bounds.width.isFinite, bounds.width > 0 else { return }

        let nonfinalPageWidth = widthForNonfinalPage(in: bounds.width)
        let stride = nonfinalPageWidth + spacing
        let lastPage = CGFloat(max(subviews.count - 1, 0))
        let shift = min(max(progress, 0), lastPage) * stride

        for index in subviews.indices {
            let origin = CGPoint(
                x: bounds.minX + CGFloat(index) * stride - shift,
                y: bounds.minY
            )
            let pageWidth = index == subviews.count - 1 ? bounds.width : nonfinalPageWidth
            let pageProposal = ProposedViewSize(width: pageWidth, height: bounds.height)

            subviews[index].place(at: origin, proposal: pageProposal)
        }
    }

}

nonisolated extension PagingHStack {

    private func concreteViewportWidth(from proposedWidth: CGFloat?) -> CGFloat? {
        guard let proposedWidth, proposedWidth.isFinite, proposedWidth > 0 else {
            return nil
        }

        return proposedWidth
    }

    private func measuredPageSizes(in viewportWidth: CGFloat?, subviews: LayoutSubviews) -> [CGSize] {
        guard let viewportWidth else {
            return subviews.map { subview in
                subview.sizeThatFits(.unspecified)
            }
        }

        let nonfinalPageWidth = widthForNonfinalPage(in: viewportWidth)

        return subviews.enumerated().map { index, subview in
            let pageWidth = index == subviews.count - 1
                ? viewportWidth
                : nonfinalPageWidth
            return subview.sizeThatFits(ProposedViewSize(width: pageWidth, height: nil))
        }
    }

    private func resolvedPagerWidth(
        for proposedWidth: CGFloat?,
        viewportWidth: CGFloat?,
        pageSizes: [CGSize]
    ) -> CGFloat {
        if let viewportWidth { return viewportWidth }
        if proposedWidth == .infinity { return .infinity }

        let trailingInset = max(pageTrailingInset, 0)
        let lastPageIndex = pageSizes.count - 1
        let requiredViewportWidths = pageSizes.enumerated().map { index, pageSize in
            let requiredInset = index == lastPageIndex ? 0 : trailingInset
            return pageSize.width + requiredInset
        }

        return requiredViewportWidths.max() ?? 0
    }

    private func resolvedPagerHeight(
        for proposedHeight: CGFloat?,
        idealHeight: CGFloat
    ) -> CGFloat {

        guard let proposedHeight, proposedHeight.isFinite else {
            return idealHeight
        }

        return max(proposedHeight, 0)
    }

    /// Returns a nonfinal page's width after clamping its trailing inset to the viewport.
    private func widthForNonfinalPage(in viewportWidth: CGFloat) -> CGFloat {
        let inset = min(max(pageTrailingInset, 0), viewportWidth)
        return viewportWidth - inset
    }

}
