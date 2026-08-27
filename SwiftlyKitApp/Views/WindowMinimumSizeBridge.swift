import AppKit
import SwiftUI

/// SwiftUI derives a minimum height that changes with width, but the window receives only one minimum `CGSize`.
/// This bridge measures the modified view, disables the hosting view's `.minSize` export, and applies separate AppKit
/// width and height limits that include the unified toolbar area outside `contentLayoutRect`.

extension View {

    /// Sets a window minimum height that follows this view's measured height.
    /// The supplied value reserves height for required content outside this view.
    func windowMinimumHeight(adding extraHeight: CGFloat = 0) -> some View {
        modifier(
            WindowMinimumHeightModifier(
                extraHeight: extraHeight
            )
        )
    }

}

/// View modifier that derives the window minimum height from measured content and a fixed height allowance.
private struct WindowMinimumHeightModifier: ViewModifier {

    /// Latest positive finite height measured for the modified view.
    @State private var viewHeight: CGFloat?

    /// Additional minimum height for required content outside the modified view.
    let extraHeight: CGFloat

    /// Measures the modified view and installs the bridge after a valid height is available.
    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.height
            } action: { height in
                guard height.isFinite, height > 0 else { return }
                viewHeight = height
            }
            .background {
                if let viewHeight {
                    WindowMinimumSizeBridge(
                        visibleMinHeight: viewHeight + extraHeight
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
    }

}

/// Type-erased access to a hosting view's automatic sizing options.
private protocol HostingViewSizingOptionsAccess: AnyObject {

    var sizingOptions: NSHostingSizingOptions { get set }

}

extension NSHostingView: HostingViewSizingOptionsAccess {}

/// SwiftUI adapter for the AppKit view that enforces the containing window's minimum size.
private struct WindowMinimumSizeBridge: NSViewRepresentable {

    /// Minimum height for visible SwiftUI content, excluding window chrome.
    let visibleMinHeight: CGFloat

    /// Creates the AppKit view that controls the containing window's minimum size.
    func makeNSView(context: Context) -> WindowMinimumSizeView {
        WindowMinimumSizeView()
    }

    /// Passes the latest visible-content minimum height to the AppKit view.
    func updateNSView(_ nsView: WindowMinimumSizeView, context: Context) {
        nsView.visibleMinHeight = visibleMinHeight
    }

}

/// AppKit view that separates SwiftUI's coupled minimum size into independent window limits.
private final class WindowMinimumSizeView: NSView {

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

    /// Updates the window limits after AppKit resolves the current layout.
    override func layout() {
        super.layout()
        updateMinimum()
    }

}

extension WindowMinimumSizeView {

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
        size.height = minContentHeight
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
