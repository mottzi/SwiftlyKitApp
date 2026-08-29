import AppKit

@MainActor
/// Returns every descendant in the supplied AppKit view hierarchy.
func descendantViews(of view: NSView) -> [NSView] {
    view.subviews.flatMap { subview in
        [subview] + descendantViews(of: subview)
    }
}
