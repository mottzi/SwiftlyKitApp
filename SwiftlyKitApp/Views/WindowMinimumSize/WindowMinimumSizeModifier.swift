import SwiftUI

/// SwiftUI derives a minimum size whose height changes with width, but the window receives only one minimum `CGSize`.
/// This bridge measures the modified view, disables the hosting view's `.minSize` export, and applies independent
/// AppKit width and height limits that include the unified toolbar area outside `contentLayoutRect`.

extension View {

    /// Sets an independent window minimum size while allowing height to follow this view's measured height.
    /// The supplied height reserves space for required content outside this view.
    func windowMinimumSize(addingHeight extraHeight: CGFloat = 0) -> some View {
        modifier(WindowMinimumSizeModifier(extraHeight: extraHeight))
    }

}

/// View modifier that derives independent window minimum dimensions from the measured content.
private struct WindowMinimumSizeModifier: ViewModifier {

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

/// SwiftUI adapter for the AppKit view that enforces the containing window's minimum size.
private struct WindowMinimumSizeBridge: NSViewRepresentable {

    /// Minimum height for visible SwiftUI content, excluding window chrome.
    let visibleMinHeight: CGFloat

    /// Creates the AppKit view that controls the containing window's minimum size.
    func makeNSView(context: Context) -> WindowMinimumSizeAppKitView {
        WindowMinimumSizeAppKitView()
    }

    /// Passes the latest visible-content minimum height to the AppKit view.
    func updateNSView(_ nsView: WindowMinimumSizeAppKitView, context: Context) {
        nsView.visibleMinHeight = visibleMinHeight
    }

}
