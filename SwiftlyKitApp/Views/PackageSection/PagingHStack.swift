import SwiftUI

/// Horizontal pager that presents one selected page with an optional trailing reveal of the next.
/// Progress shifts the page row to show the selected page.
struct PagingHStack {

    /// Gap between adjacent pages.
    let spacing: CGFloat

    /// Amount by which each nonfinal page is narrower than the pager viewport.
    let pageTrailingInset: CGFloat

    /// Page index. 0 is the first page. A fraction is a position between pages.
    var progress: CGFloat
    
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
    
    /// Returns the pager's size for a parent proposal, with variable page widths and enough height for every page.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        
        // respect a usable parent width, and fall back to content-driven sizing only when it is unavailable
        let viewportWidth: CGFloat?
    
        // accept only a positive finite proposal as a concrete pager viewport
        if let proposedWidth = proposal.width,
           proposedWidth.isFinite,
           proposedWidth > 0 {
            
            viewportWidth = proposedWidth
        } else {
            viewportWidth = nil
        }
        
        // measure every page using either its concrete page width or its ideal width
        let childSizes: [CGSize]
        
        // apply the concrete viewport to page measurement
        if let viewportWidth {
            // reserve the trailing reveal by narrowing every nonfinal page
            let nonfinalPageWidth = widthForNonfinalPage(in: viewportWidth)
            
            // measure nonfinal pages at their reduced width and the final page at the full viewport width
            childSizes = subviews.enumerated().map { index, subview in
                let pageWidth = index == subviews.count - 1 ? viewportWidth : nonfinalPageWidth
                return subview.sizeThatFits(ProposedViewSize(width: pageWidth, height: nil))
            }
        } else {
            // ask every page for its ideal size when no concrete viewport exists
            childSizes = subviews.map { subview in
                subview.sizeThatFits(.unspecified)
            }
        }
        
        // make the pager as tall as its tallest page
        let tallestHeight = childSizes.map(\.height).max() ?? 0
        
        // resolve the pager width for the parent's sizing proposal
        let pagerWidth: CGFloat
        
        if let viewportWidth {
            // fill a concrete viewport supplied by the parent
            pagerWidth = viewportWidth
        } else if proposal.width == .infinity {
            // preserve an unbounded width while the parent measures maximum flexibility
            pagerWidth = .infinity
        } else {
            // fit zero and unspecified proposals to the widest ideal page viewport
            let trailingInset = max(pageTrailingInset, 0)
            let lastPageIndex = childSizes.count - 1
            
            // convert each ideal page width into the viewport width needed to contain it
            let requiredViewportWidths = childSizes.enumerated().map { index, childSize in
                // nonfinal pages need room for their content plus the reserved trailing inset
                let requiredInset = index == lastPageIndex ? 0 : trailingInset
                // add back the inset that placement subtracts from each nonfinal page
                return childSize.width + requiredInset
            }

            // use the widest requirement as the pager's minimum and ideal width
            pagerWidth = requiredViewportWidths.max() ?? 0
        }
        
        return CGSize(width: pagerWidth, height: tallestHeight)
    }
    
    /// Places nonfinal pages at their reduced width and the final page at the full viewport width.
    /// Progress shifts the row by the nonfinal page width plus spacing.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        
        // abort if the pager's assigned rectangle has no positive finite width
        guard bounds.width.isFinite, bounds.width > 0 else { return }
        
        let nonfinalPageWidth = widthForNonfinalPage(in: bounds.width)
        
        // calculate the offset between adjacent pages using the nonfinal page width
        let stride = nonfinalPageWidth + spacing
        
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
            
            // keep the final page full-width while preserving the trailing reveal on nonfinal pages
            let pageWidth = index == subviews.count - 1 ? bounds.width : nonfinalPageWidth
            
            // pass each page its assigned width and the pager's available height
            let pageProposal = ProposedViewSize(width: pageWidth, height: bounds.height)
            
            // place the page at that point
            subviews[index].place(at: origin, proposal: pageProposal)
        }
    }
    
}

nonisolated extension PagingHStack {

    /// Returns a nonfinal page's width after clamping its trailing inset to the viewport.
    private func widthForNonfinalPage(in viewportWidth: CGFloat) -> CGFloat {
        let inset = min(max(pageTrailingInset, 0), viewportWidth)
        return viewportWidth - inset
    }

}
