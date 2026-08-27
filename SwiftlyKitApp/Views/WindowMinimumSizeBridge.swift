import AppKit
import SwiftUI

@MainActor
private protocol HostingViewSizingOptionsAccess: AnyObject {

    var sizingOptions: NSHostingSizingOptions { get set }

}

extension NSHostingView: HostingViewSizingOptionsAccess {}

/// Synchronizes a SwiftUI content height requirement with its containing window.
struct WindowMinimumSizeBridge: NSViewRepresentable {

    let minimumHeight: CGFloat

    func makeNSView(context: Context) -> WindowMinimumSizeView {
        WindowMinimumSizeView()
    }

    func updateNSView(_ nsView: WindowMinimumSizeView, context: Context) {
        nsView.minimumHeight = minimumHeight
    }

}

final class WindowMinimumSizeView: NSView {

    var minimumHeight = CGFloat.zero {
        didSet {
            needsLayout = true
        }
    }

    private weak var heightConstraintItem: AnyObject?
    private var minimumHeightConstraint: NSLayoutConstraint?
    private weak var widthConstraintItem: AnyObject?
    private var minimumWidthConstraint: NSLayoutConstraint?
    private var didRemoveHostingMinimumSizing = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        needsLayout = true
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            minimumHeightConstraint?.isActive = false
            minimumHeightConstraint = nil
            heightConstraintItem = nil
            minimumWidthConstraint?.isActive = false
            minimumWidthConstraint = nil
            widthConstraintItem = nil
            didRemoveHostingMinimumSizing = false
        }

        super.viewWillMove(toWindow: newWindow)
    }

    override func layout() {
        super.layout()
        updateWindowMinimum()
    }

    private func updateWindowMinimum() {
        guard let window else { return }
        guard minimumHeight.isFinite, minimumHeight > 0 else { return }

        guard let hostingView = hostingView() else { return }
        guard let contentView = window.contentView else { return }

        // The hosting view extends behind the unified toolbar. Add the obscured region so the
        // SwiftUI minimum describes the window-sized hosting view rather than only visible content.
        let obscuredContentHeight = max(
            window.frame.height - window.contentLayoutRect.height,
            0
        )
        let requiredWindowHeight = minimumHeight + obscuredContentHeight

        // Keep SwiftUI's ideal-size measurement available while we replace only its coupled minimum.
        enableHostingIntrinsicSizing(on: hostingView)

        // Preserve SwiftUI's horizontal content minimum before removing the coupled width-and-height option.
        let contentMinimumWidth = didRemoveHostingMinimumSizing ? 0 : window.contentMinSize.width
        let hostingMinimumWidth = max(contentMinimumWidth, minimumWidth(for: hostingView))
        removeHostingViewMinimumSizing(from: hostingView)
        didRemoveHostingMinimumSizing = true

        // Auto Layout ignores contentMinSize, so keep the height floor on the view that hosts
        // the full SwiftUI hierarchy and the width floor on the visible content region.
        let contentLayoutGuide = window.contentLayoutGuide as? NSLayoutGuide
        installMinimumHeightConstraint(
            on: hostingView,
            heightAnchor: hostingView.heightAnchor,
            minimumHeight: requiredWindowHeight
        )

        if let contentLayoutGuide {
            installMinimumWidthConstraint(
                on: contentLayoutGuide,
                widthAnchor: contentLayoutGuide.widthAnchor,
                minimumWidth: hostingMinimumWidth
            )
        } else {
            installMinimumWidthConstraint(
                on: hostingView,
                widthAnchor: hostingView.widthAnchor,
                minimumWidth: hostingMinimumWidth
            )
        }

        let visibleContentWidth = contentLayoutGuide?.frame.width ?? contentView.bounds.width
        guard visibleContentWidth.isFinite, visibleContentWidth > 0 else { return }

        let obscuredContentWidth = max(contentView.bounds.width - visibleContentWidth, 0)
        let requiredContentWidth = hostingMinimumWidth + obscuredContentWidth

        var contentMinimumSize = window.contentMinSize
        contentMinimumSize.width = requiredContentWidth
        contentMinimumSize.height = requiredWindowHeight

        if contentMinimumSize != window.contentMinSize {
            window.contentMinSize = contentMinimumSize
        }

        guard contentView.bounds.width < requiredContentWidth
                || contentView.bounds.height < requiredWindowHeight else { return }

        var contentSize = contentView.bounds.size
        contentSize.width = max(contentSize.width, requiredContentWidth)
        contentSize.height = requiredWindowHeight
        window.setContentSize(contentSize)
    }

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

    private func removeHostingViewMinimumSizing(from hostingView: NSView) {
        guard let hostingView = hostingView as? any HostingViewSizingOptionsAccess else {
            return
        }

        var sizingOptions = hostingView.sizingOptions
        sizingOptions.remove(.minSize)

        if sizingOptions != hostingView.sizingOptions {
            hostingView.sizingOptions = sizingOptions
        }
    }

    private func enableHostingIntrinsicSizing(on hostingView: NSView) {
        guard let hostingView = hostingView as? any HostingViewSizingOptionsAccess else {
            return
        }

        var sizingOptions = hostingView.sizingOptions
        sizingOptions.insert(.intrinsicContentSize)

        if sizingOptions != hostingView.sizingOptions {
            hostingView.sizingOptions = sizingOptions
        }
    }

    private func installMinimumHeightConstraint(
        on layoutItem: AnyObject,
        heightAnchor: NSLayoutDimension,
        minimumHeight: CGFloat
    ) {
        if heightConstraintItem !== layoutItem {
            minimumHeightConstraint?.isActive = false
            minimumHeightConstraint = heightAnchor.constraint(
                greaterThanOrEqualToConstant: minimumHeight
            )
            minimumHeightConstraint?.priority = .required
            minimumHeightConstraint?.isActive = true
            heightConstraintItem = layoutItem
        } else {
            minimumHeightConstraint?.constant = minimumHeight
        }
    }

    /// Returns the widest width reported by the SwiftUI hosting hierarchy.
    private func minimumWidth(for hostingView: NSView) -> CGFloat {
        [hostingView.fittingSize.width, hostingView.intrinsicContentSize.width]
            .filter { $0.isFinite && $0 > 0 }
            .max() ?? 0
    }

    private func installMinimumWidthConstraint(
        on layoutItem: AnyObject,
        widthAnchor: NSLayoutDimension,
        minimumWidth: CGFloat
    ) {
        guard minimumWidth.isFinite, minimumWidth > 0 else { return }

        if widthConstraintItem !== layoutItem {
            minimumWidthConstraint?.isActive = false
            minimumWidthConstraint = widthAnchor.constraint(
                greaterThanOrEqualToConstant: minimumWidth
            )
            minimumWidthConstraint?.priority = .required
            minimumWidthConstraint?.isActive = true
            widthConstraintItem = layoutItem
        } else {
            minimumWidthConstraint?.constant = minimumWidth
        }
    }

}
