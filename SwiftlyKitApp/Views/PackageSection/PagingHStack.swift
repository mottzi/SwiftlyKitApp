import SwiftUI

/// Horizontal pager that shows one page at a time.
/// Progress shifts the page row to show the selected page.
struct PagingHStack: Layout, Animatable {

    /// Gap between adjacent pages.
    let spacing: CGFloat

    /// Page index. 0 is the first page. A fraction is a position between pages.
    var progress: CGFloat

}

extension PagingHStack {

    init(spacing: CGFloat = 10, selection: Int) {
        self.spacing = spacing
        self.progress = CGFloat(selection)
    }

    init(spacing: CGFloat = 10, selection: some RawRepresentable<Int>) {
        self.init(
            spacing: spacing,
            selection: selection.rawValue
        )
    }

    /// Interpolates `progress` during page transitions.
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    /// Returns the pager's size for a parent proposal, one page wide and tall enough for every page.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {

        var childWidthProposal: CGFloat?

        // keep the parent's positive finite width for child measurement and pager sizing
        if let parentProposedWidth = proposal.width,
           parentProposedWidth.isFinite,
           parentProposedWidth > 0 {

            childWidthProposal = parentProposedWidth
        }

        // propose the parent's positive finite width if present and leave height unspecified
        let childProposal = ProposedViewSize(width: childWidthProposal, height: nil)

        // ask each page for the size it chooses under this proposal
        let childSizes = subviews.map { $0.sizeThatFits(childProposal) }

        // make the pager as tall as its tallest page
        let tallestHeight = childSizes.map(\.height).max() ?? 0

        // let the parent choose the width, or fit the pager to its widest page
        return if let childWidthProposal {
            CGSize(width: childWidthProposal, height: tallestHeight)
        } else if proposal.width == .infinity {
            CGSize(width: .infinity, height: tallestHeight)
        } else {
            CGSize(width: childSizes.map(\.width).max() ?? 0, height: tallestHeight)
        }
    }

    /// Places each page in the rectangle assigned to the pager, one page width plus spacing apart.
    /// Progress shifts the row to show the selected page.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {

        // abort if the pager's assigned rectangle has no positive finite width
        guard bounds.width.isFinite, bounds.width > 0 else { return }

        // propose the pager's full size to each page
        let pageProposal = ProposedViewSize(width: bounds.width, height: bounds.height)

        // calculate the fixed horizontal offset between adjacent pages
        let stride = bounds.width + spacing

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

            // place the page at that point
            subviews[index].place(at: origin, proposal: pageProposal)
        }
    }

}
