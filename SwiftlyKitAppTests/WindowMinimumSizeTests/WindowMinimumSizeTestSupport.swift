import AppKit
import SwiftUI
@testable import SwiftlyKitApp

struct ResponsiveMinimumContent: View {

    static let reservedHeight = CGFloat(250)

    var body: some View {
        WidthResponsiveLayout {
            Color.clear
        }
        .frame(minWidth: 334)
    }

}

private struct WidthResponsiveLayout: Layout {

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = max(proposal.width ?? 334, 334)
        let height: CGFloat = width >= 500 ? 178 : 250
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        for subview in subviews {
            subview.place(
                at: bounds.origin,
                anchor: .topLeading,
                proposal: ProposedViewSize(
                    width: bounds.width,
                    height: bounds.height
                )
            )
        }
    }

}

final class ContentSizeRecursionRecordingWindow: NSWindow {

    var didResizeReentrantly = false

    var isBridgeLayoutActive = false

    override func setContentSize(_ size: NSSize) {
        if isBridgeLayoutActive {
            didResizeReentrantly = true
        }

        super.setContentSize(size)
    }

}

struct WindowMinimumSizeTestBridge: NSViewRepresentable {

    let visibleMinHeight: CGFloat

    func makeNSView(context: Context) -> WindowMinimumSizeAppKitView {
        WindowMinimumSizeAppKitView()
    }

    func updateNSView(_ nsView: WindowMinimumSizeAppKitView, context: Context) {
        nsView.visibleMinHeight = visibleMinHeight
    }

}
