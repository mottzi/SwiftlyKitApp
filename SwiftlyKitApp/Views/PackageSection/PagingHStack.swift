import SwiftUI

/// Horizontal pager. One page wide and as tall as the tallest page.
/// Progress slides which page sits at the left edge.
struct PagingHStack: Layout {
    
    /// Distance between adjacent pages.
    let spacing: CGFloat
    
    /// Page index. 0 is the first page. A fraction is a position between pages.
    var progress: CGFloat
    
    init(spacing: CGFloat = 16, selection: Int) {
        self.spacing = spacing
        self.progress = CGFloat(selection)
    }
    
    init(spacing: CGFloat = 16, selection: some RawRepresentable<Int>) {
        self.init(
            spacing: spacing,
            selection: selection.rawValue
        )
    }
    
}

extension PagingHStack {
    
    /// Progress that SwiftUI interpolates to animate the page slide.
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    /// Layout size. Height is the tallest page's ideal height.
    /// Width is the finite proposed width, infinity, or the widest page.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
           
        var pageWidth: CGFloat? = nil
        
        // if proposed width is positive and finite
        if let proposedWidth = proposal.width,
           proposedWidth.isFinite,
           proposedWidth > 0 {
            
            // take this concrete proposed width as page width
            pageWidth = proposedWidth
        }

        // measure subviews at page width and unspecified height
        let childProposal = ProposedViewSize(width: pageWidth, height: nil)
        let childSizes = subviews.map { $0.sizeThatFits(childProposal) }
        
        // tallest page height will be layout height
        let tallestHeight = childSizes.map(\.height).max() ?? 0

        // return the page width, an infinite width, or the current page's width
        let width: CGFloat
        if let pageWidth {
            width = pageWidth
        } else if proposal.width == .infinity {
            width = .infinity
        } else {
            let pageIndex = min(
                max(Int(progress.rounded()), 0),
                max(childSizes.count - 1, 0)
            )
            width = childSizes.indices.contains(pageIndex)
                ? childSizes[pageIndex].width
                : 0
        }

        return CGSize(width: width, height: tallestHeight)
    }

    /// Places pages in a row one page width plus spacing apart, then shifts the row by progress.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
                
        // abort if there is no positive finite page width
        guard bounds.width.isFinite, bounds.width > 0 else { return }

        // propose the full bounds to each page
        let pageProposal = ProposedViewSize(width: bounds.width, height: bounds.height)
        
        // space pages one stride apart
        let stride = bounds.width + spacing
        
        // clamp progress to the page range and convert it to a shift
        let lastPage = CGFloat(max(subviews.count - 1, 0))
        let shift = min(max(progress, 0), lastPage) * stride

        for index in subviews.indices {
            // put this page at its stride slot in the shifted row
            let origin = CGPoint(
                x: bounds.minX + CGFloat(index) * stride - shift,
                y: bounds.minY
            )
            
            // place each page at the origin
            subviews[index].place(at: origin, proposal: pageProposal)
        }
    }
    
}
