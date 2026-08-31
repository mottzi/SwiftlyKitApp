import AppKit
import SwiftUI

/// AppKit view that separates SwiftUI's coupled minimum size into independent window limits.
final class WindowMinimumSizeAppKitView: NSView {

    /// Minimum height for visible SwiftUI content, excluding window chrome.
    var visibleMinHeight = CGFloat.zero {
        didSet {
            needsLayout = true
        }
    }

    /// Layout item that owns `minHeightConstraint`.
    private weak var heightItem: AnyObject?

    /// Active required minimum-height constraint.
    private var minHeightConstraint: NSLayoutConstraint?

    /// Layout item that owns `minWidthConstraint`.
    private weak var widthItem: AnyObject?

    /// Active required minimum-width constraint.
    private var minWidthConstraint: NSLayoutConstraint?

    /// Whether the hosting view's `.minSize` sizing option was removed.
    private var didDisableHostMinSize = false

    /// Coalesces window updates until the active AppKit layout pass has returned.
    private var minimumUpdateTask: Task<Void, Never>?

    /// Schedules a minimum-size update after the window association changes.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        needsLayout = true
    }

    /// Removes window-specific constraints before detachment.
    override func viewWillMove(toWindow newWindow: NSWindow?) {

        if newWindow == nil {
            minHeightConstraint?.isActive = false
            minHeightConstraint = nil
            heightItem = nil
            minWidthConstraint?.isActive = false
            minWidthConstraint = nil
            widthItem = nil
            didDisableHostMinSize = false
        }

        super.viewWillMove(toWindow: newWindow)
    }

    /// Schedules the window limits to update after AppKit resolves the current layout.
    override func layout() {
        super.layout()
        scheduleMinimumUpdate()
    }

}

extension WindowMinimumSizeAppKitView {

    /// Defers window mutations because resizing a window from `layout()` re-enters AppKit layout.
    private func scheduleMinimumUpdate() {
        guard minimumUpdateTask == nil else { return }

        minimumUpdateTask = Task { [weak self] in
            await Task.yield()
            guard let self else { return }

            updateMinimum()
            minimumUpdateTask = nil
        }
    }

    /// Applies independent width and height minimums to the containing window.
    private func updateMinimum() {
        guard let window else { return }
        guard visibleMinHeight.isFinite, visibleMinHeight > 0 else { return }

        guard let hostingView = hostingView() else { return }
        guard let contentView = window.contentView else { return }

        // add the unified toolbar region so visible content keeps the requested minimum height
        let layoutInsetHeight = max(
            window.frame.height - window.contentLayoutRect.height,
            0
        )
        let minContentHeight = visibleMinHeight + layoutInsetHeight

        // retain ideal-size measurement after disabling SwiftUI's coupled minimum-size export
        enableHostIntrinsicSize(on: hostingView)

        // capture SwiftUI's initial width minimum before disabling its coupled minimum-size export
        let existingMinWidth = didDisableHostMinSize ? 0 : window.contentMinSize.width
        let minLayoutWidth = max(existingMinWidth, reportedWidth(for: hostingView))
        disableHostMinSize(on: hostingView)
        didDisableHostMinSize = true

        // enforce independent dimensions because contentMinSize does not affect Auto Layout
        let layoutGuide = window.contentLayoutGuide as? NSLayoutGuide
        setMinHeightConstraint(
            on: hostingView,
            anchor: hostingView.heightAnchor,
            minimum: minContentHeight
        )

        if let layoutGuide {
            setMinWidthConstraint(
                on: layoutGuide,
                anchor: layoutGuide.widthAnchor,
                minimum: minLayoutWidth
            )
        } else {
            setMinWidthConstraint(
                on: hostingView,
                anchor: hostingView.widthAnchor,
                minimum: minLayoutWidth
            )
        }

        let layoutWidth = layoutGuide?.frame.width ?? contentView.bounds.width
        guard layoutWidth.isFinite, layoutWidth > 0 else { return }

        let layoutInsetWidth = max(contentView.bounds.width - layoutWidth, 0)
        let minContentWidth = minLayoutWidth + layoutInsetWidth

        // prevent user resizing below either independent minimum
        var minSize = window.contentMinSize
        minSize.width = minContentWidth
        minSize.height = minContentHeight

        if minSize != window.contentMinSize {
            window.contentMinSize = minSize
        }

        guard contentView.bounds.width < minContentWidth
                || contentView.bounds.height < minContentHeight else { return }

        // restore the minimum if a layout transition leaves the window too small
        var size = contentView.bounds.size
        size.width = max(size.width, minContentWidth)
        size.height = max(size.height, minContentHeight)
        window.setContentSize(size)
    }

    /// Returns the nearest ancestor that exposes hosting-view sizing options.
    private func hostingView() -> NSView? {
        var ancestor = superview

        while let view = ancestor {
            if view is any HostingViewSizingOptionsAccess {
                return view
            }

            ancestor = view.superview
        }

        return nil
    }

    /// Stops the hosting view from exporting a coupled minimum size.
    private func disableHostMinSize(on hostingView: NSView) {
        guard let hostingView = hostingView as? any HostingViewSizingOptionsAccess else {
            return
        }

        var sizingOptions = hostingView.sizingOptions
        sizingOptions.remove(.minSize)

        if sizingOptions != hostingView.sizingOptions {
            hostingView.sizingOptions = sizingOptions
        }
    }

    /// Keeps the hosting view's intrinsic size available for width measurement.
    private func enableHostIntrinsicSize(on hostingView: NSView) {
        guard let hostingView = hostingView as? any HostingViewSizingOptionsAccess else {
            return
        }

        var sizingOptions = hostingView.sizingOptions
        sizingOptions.insert(.intrinsicContentSize)

        if sizingOptions != hostingView.sizingOptions {
            hostingView.sizingOptions = sizingOptions
        }
    }

    /// Creates or updates the required minimum-height constraint for `item`.
    private func setMinHeightConstraint(on item: AnyObject, anchor: NSLayoutDimension, minimum: CGFloat) {
        if heightItem !== item {
            minHeightConstraint?.isActive = false
            minHeightConstraint = anchor.constraint(
                greaterThanOrEqualToConstant: minimum
            )
            minHeightConstraint?.priority = .required
            minHeightConstraint?.isActive = true
            heightItem = item
        } else {
            minHeightConstraint?.constant = minimum
        }
    }

    /// Returns the largest positive finite width from the hosting view's fitting and intrinsic sizes.
    private func reportedWidth(for hostingView: NSView) -> CGFloat {
        [hostingView.fittingSize.width, hostingView.intrinsicContentSize.width]
            .filter { $0.isFinite && $0 > 0 }
            .max() ?? 0
    }

    /// Creates or updates the required minimum-width constraint for `item`.
    private func setMinWidthConstraint(on item: AnyObject, anchor: NSLayoutDimension, minimum: CGFloat) {
        guard minimum.isFinite, minimum > 0 else { return }

        if widthItem !== item {
            minWidthConstraint?.isActive = false
            minWidthConstraint = anchor.constraint(
                greaterThanOrEqualToConstant: minimum
            )
            minWidthConstraint?.priority = .required
            minWidthConstraint?.isActive = true
            widthItem = item
        } else {
            minWidthConstraint?.constant = minimum
        }
    }

}

/// Type-erased access to a hosting view's automatic sizing options.
private protocol HostingViewSizingOptionsAccess: AnyObject {

    var sizingOptions: NSHostingSizingOptions { get set }

}

///
extension NSHostingView: HostingViewSizingOptionsAccess {}
