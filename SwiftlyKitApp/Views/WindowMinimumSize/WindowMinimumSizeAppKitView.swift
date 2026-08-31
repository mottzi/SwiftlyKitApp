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

    /// Original SwiftUI minimum width for the managed hosting view and window.
    private var swiftUIMinWidth: CGFloat?

    /// Hosting view whose sizing options are currently managed by this bridge.
    private weak var managedHostingView: NSView?

    /// Sizing options to restore when the managed hosting view detaches.
    private var originalHostingSizingOptions: NSHostingSizingOptions?

    /// Reapplies independent limits if SwiftUI publishes a late coupled minimum update.
    private var contentMinSizeObservation: NSKeyValueObservation?

    /// Coalesces window updates until the active AppKit layout pass has returned.
    private var minimumUpdateTask: Task<Void, Never>?

    /// Schedules a minimum-size update after the window association changes.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        needsLayout = true
    }

    /// Removes window-specific constraints before detachment.
    override func viewWillMove(toWindow newWindow: NSWindow?) {

        if window !== newWindow {
            minimumUpdateTask?.cancel()
            minimumUpdateTask = nil
            releaseManagedWindowState()
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
            guard !Task.isCancelled else { return }
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

        beginManaging(hostingView, in: window)

        // capture SwiftUI's width floor before changing the hosting view's sizing policy
        if !didDisableHostMinSize {
            let width = window.contentMinSize.width

            if width.isFinite, width > 0 {
                swiftUIMinWidth = width
            }
        }

        configureHostSizing(on: hostingView)
        didDisableHostMinSize = true

        // add the unified toolbar region so visible content keeps the requested minimum height
        let layoutInsetHeight = max(
            window.frame.height - window.contentLayoutRect.height,
            0
        )
        let minContentHeight = visibleMinHeight + layoutInsetHeight

        let minLayoutWidth = max(
            swiftUIMinWidth ?? 0,
            reportedWidth(for: hostingView)
        )
        let layoutGuide = window.contentLayoutGuide as? NSLayoutGuide
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

        if contentView.bounds.width < minContentWidth
                || contentView.bounds.height < minContentHeight {
            // enlarge first so required layout constraints never conflict with the current frame
            var size = contentView.bounds.size
            size.width = max(size.width, minContentWidth)
            size.height = max(size.height, minContentHeight)
            window.setContentSize(size)
        }

        // enforce independent dimensions because contentMinSize does not affect Auto Layout
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

    }

    /// Records the host's original sizing policy before changing it.
    private func beginManaging(_ hostingView: NSView, in window: NSWindow) {
        guard managedHostingView !== hostingView else { return }

        releaseManagedWindowState()
        managedHostingView = hostingView
        originalHostingSizingOptions = (
            hostingView as? any HostingViewSizingOptionsAccess
        )?.sizingOptions
        contentMinSizeObservation = window.observe(\.contentMinSize) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.needsLayout = true
            }
        }
    }

    /// Removes owned constraints and restores the hosting view's sizing policy.
    private func releaseManagedWindowState() {
        minHeightConstraint?.isActive = false
        minHeightConstraint = nil
        heightItem = nil
        minWidthConstraint?.isActive = false
        minWidthConstraint = nil
        widthItem = nil
        contentMinSizeObservation = nil

        if
            let managedHostingView = managedHostingView as? any HostingViewSizingOptionsAccess,
            let originalHostingSizingOptions
        {
            managedHostingView.sizingOptions = originalHostingSizingOptions
        }

        managedHostingView = nil
        originalHostingSizingOptions = nil
        didDisableHostMinSize = false
        swiftUIMinWidth = nil
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

    /// Enables ideal-size reporting while removing the host's coupled minimum-size export.
    private func configureHostSizing(on hostingView: NSView) {
        guard let hostingView = hostingView as? any HostingViewSizingOptionsAccess else {
            return
        }

        var sizingOptions = hostingView.sizingOptions
        sizingOptions.insert(.intrinsicContentSize)
        sizingOptions.remove(.minSize)

        guard sizingOptions != hostingView.sizingOptions else { return }

        hostingView.sizingOptions = sizingOptions
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
            // AppKit's required frame equality must win during a transient resize proposal.
            minWidthConstraint?.priority = NSLayoutConstraint.Priority(
                rawValue: NSLayoutConstraint.Priority.required.rawValue - 1
            )
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
