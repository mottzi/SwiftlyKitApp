import SwiftUI
    
/// Horizontal pager that is one page wide and as tall as the tallest child. Children move by progress.
struct PagingHStack {
    
    /// Distance between adjacent pages.
    let spacing: CGFloat
    
    /// Page position as a fractional index.
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

nonisolated extension PagingHStack: Layout {
    
    /// Progress value that SwiftUI interpolates.
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    /// Returns the pager size. Height is the tallest child's ideal height. Width is the proposed page width, infinity, or the widest child.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
                        
        var pageWidth: CGFloat?
        
        if let proposedWidth = proposal.width,
           proposedWidth.isFinite,
           proposedWidth > 0 {
            
            // take the proposed width as the page width
            pageWidth = proposedWidth
        }

        // measure children at page width and ideal height
        let childProposal = ProposedViewSize(width: pageWidth, height: nil)
        let childSizes = subviews.map { $0.sizeThatFits(childProposal) }
        
        // get the tallest child's height
        let tallestHeight = childSizes.map(\.height).max() ?? 0

        //
        return if let pageWidth {
            // return the page width
            CGSize(width: pageWidth, height: tallestHeight)
        } else if proposal.width == .infinity {
            // return an infinite width if the proposal is infinite
            CGSize(width: .infinity, height: tallestHeight)
        } else {
            // return the widest child if the proposal is a minimum or unspecified width
            CGSize(width: childSizes.map(\.width).max() ?? 0, height: tallestHeight)
        }
    }

    /// Places each page one stride apart and shifts the row by progress.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        
        let pageWidth = bounds.width
        
        // Same NaN/0 path that used to explode window geometry.
        guard pageWidth.isFinite, pageWidth > 0 else { return }

        // propose the full bounds to each page
        let pageProposal = ProposedViewSize(width: pageWidth, height: bounds.height)
        
        // add spacing to the page width
        let stride = pageWidth + spacing
        
        // get the last page index
        let lastPage = CGFloat(max(subviews.count - 1, 0))
        
        // limit progress to the page range and convert it to a distance
        let shift = min(max(progress, 0), lastPage) * stride

        for index in subviews.indices {
            // put the page at index times stride minus shift
            let origin = CGPoint(
                x: bounds.minX + CGFloat(index) * stride - shift,
                y: bounds.minY
            )
            
            // place the child at the origin
            subviews[index].place(at: origin, proposal: pageProposal)
        }
    }
    
}
