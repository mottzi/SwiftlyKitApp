import AppKit
import SwiftUI

/// SwiftUI computes the correct width-dependent height, but it exports one coupled minimum size to the window.
/// This bridge measures the active SwiftUI height, disables the hosting view's coupled `.minSize` export, and applies
/// independent AppKit limits after adding the unified toolbar region excluded from `contentLayoutRect`.

extension View {

    /// Sets the window's minimum height to this view's measured height plus `additionalContentHeight`.
    /// The minimum updates if this view's height changes.
    func windowMinimumHeight(additionalContentHeight: CGFloat = 0) -> some View {
        modifier(
            WindowMinimumHeightModifier(
                additionalContentHeight: additionalContentHeight
            )
        )
    }

}

/// Window minimum that follows the modified view's height as its width changes.
private struct WindowMinimumHeightModifier: ViewModifier {

    let additionalContentHeight: CGFloat

    @State private var measuredContentHeight: CGFloat?

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.height
            } action: { height in
                guard height.isFinite, height > 0 else { return }
                measuredContentHeight = height
            }
            .background {
                if let measuredContentHeight {
                    WindowMinimumSizeBridge(
                        minimumHeight: measuredContentHeight + additionalContentHeight
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
    }

}

@MainActor
/// Mutable access to a hosting view's automatic sizing options.
private protocol HostingViewSizingOptionsAccess: AnyObject {

    var sizingOptions: NSHostingSizingOptions { get set }

}

extension NSHostingView: HostingViewSizingOptionsAccess {}

/// AppKit adapter that applies a measured content height as the containing window's minimum height.
private struct WindowMinimumSizeBridge: NSViewRepresentable {

    let minimumHeight: CGFloat

    func makeNSView(context: Context) -> WindowMinimumSizeView {
        WindowMinimumSizeView()
    }

    func updateNSView(_ nsView: WindowMinimumSizeView, context: Context) {
        nsView.minimumHeight = minimumHeight
    }

}

/// AppKit view that separates SwiftUI's coupled minimum size into independent width and height limits.
private final class WindowMinimumSizeView: NSView {

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

        // add the unified toolbar region so visible content keeps the requested minimum height
        let obscuredContentHeight = max(
            window.frame.height - window.contentLayoutRect.height,
            0
        )
        let requiredWindowHeight = minimumHeight + obscuredContentHeight

        // retain ideal-size measurement after disabling SwiftUI's coupled minimum-size export
        enableHostingIntrinsicSizing(on: hostingView)

        // capture SwiftUI's initial width minimum before disabling its coupled minimum-size export
        let contentMinimumWidth = didRemoveHostingMinimumSizing ? 0 : window.contentMinSize.width
        let hostingMinimumWidth = max(contentMinimumWidth, minimumWidth(for: hostingView))
        removeHostingViewMinimumSizing(from: hostingView)
        didRemoveHostingMinimumSizing = true

        // enforce independent dimensions because contentMinSize does not affect Auto Layout
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

        // prevent user resizing below either independent minimum
        var contentMinimumSize = window.contentMinSize
        contentMinimumSize.width = requiredContentWidth
        contentMinimumSize.height = requiredWindowHeight

        if contentMinimumSize != window.contentMinSize {
            window.contentMinSize = contentMinimumSize
        }

        guard contentView.bounds.width < requiredContentWidth
                || contentView.bounds.height < requiredWindowHeight else { return }

        // restore the minimum if a layout transition leaves the window too small
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

    /// Returns the largest positive finite width from the hosting view's fitting and intrinsic sizes.
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
