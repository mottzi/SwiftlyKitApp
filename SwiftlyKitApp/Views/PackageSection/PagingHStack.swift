import SwiftUI

/// Horizontal pager that shows one page at a time.
/// Progress shifts the page row to show the selected page.
struct PagingHStack: Layout, Animatable {

    /// Gap between adjacent pages.
    let spacing: CGFloat

    /// Amount by which each nonfinal page is narrower than the pager viewport.
    let pageTrailingInset: CGFloat

    /// Page index. 0 is the first page. A fraction is a position between pages.
    var progress: CGFloat

}

extension PagingHStack {

    init(spacing: CGFloat = 12, pageTrailingInset: CGFloat = 0, selection: Int) {
        self.spacing = spacing
        self.pageTrailingInset = pageTrailingInset
        self.progress = CGFloat(selection)
    }

    init(spacing: CGFloat = 12, pageTrailingInset: CGFloat = 0, selection: some RawRepresentable<Int>) {
        self.init(
            spacing: spacing,
            pageTrailingInset: pageTrailingInset,
            selection: selection.rawValue
        )
    }

    /// Interpolates `progress` during page transitions.
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    /// Returns the pager's size for a parent proposal, with variable page widths and enough height for every page.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {

        let childSizes: [CGSize]

        // use the parent's positive finite width as the pager viewport
        if let viewportWidth = proposal.width,
           viewportWidth.isFinite,
           viewportWidth > 0 {

            let inset = min(max(pageTrailingInset, 0), viewportWidth)
            let regularPageWidth = viewportWidth - inset

            // measure nonfinal pages at the regular width and the final page at the full viewport width
            childSizes = subviews.enumerated().map { index, subview in
                let pageWidth = index == subviews.count - 1 ? viewportWidth : regularPageWidth
                return subview.sizeThatFits(ProposedViewSize(width: pageWidth, height: nil))
            }
        } else {
            // preserve the existing fallback when the parent supplies no positive finite width
            childSizes = subviews.map {
                $0.sizeThatFits(ProposedViewSize(width: nil, height: nil))
            }
        }

        // make the pager as tall as its tallest page
        let tallestHeight = childSizes.map(\.height).max() ?? 0

        // let the parent choose the width, or fit the pager to its widest page
        return if let viewportWidth = proposal.width,
                    viewportWidth.isFinite,
                    viewportWidth > 0 {
            CGSize(width: viewportWidth, height: tallestHeight)
        } else if proposal.width == .infinity {
            CGSize(width: .infinity, height: tallestHeight)
        } else {
            CGSize(width: childSizes.map(\.width).max() ?? 0, height: tallestHeight)
        }
    }

    /// Places nonfinal pages at a regular width and the final page at the full viewport width.
    /// Progress shifts the row by the regular page width plus spacing.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {

        // abort if the pager's assigned rectangle has no positive finite width
        guard bounds.width.isFinite, bounds.width > 0 else { return }

        let inset = min(max(pageTrailingInset, 0), bounds.width)
        let regularPageWidth = bounds.width - inset

        // calculate the offset between adjacent pages using the regular page width
        let stride = regularPageWidth + spacing

        // find the highest valid page index
        let lastPage = CGFloat(max(subviews.count - 1, 0))

        // clamp progress to that range and translate it into a horizontal shift
        let shift = min(max(progress, 0), lastPage) * stride

        for index in subviews.indices {
            // calculate where this page should be placed after the row shift
            let origin = CGPoint(
                x: bounds.minX + CGFloat(index) * stride - shift,
                y: bounds.minY
            )

            let pageWidth = index == subviews.count - 1 ? bounds.width : regularPageWidth
            let pageProposal = ProposedViewSize(width: pageWidth, height: bounds.height)

            // place the page at that point
            subviews[index].place(at: origin, proposal: pageProposal)
        }
    }

}
