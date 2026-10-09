import AppKit
import SwiftUI
import Testing

extension WindowMinimumSizeTests {

    @MainActor
    @Test
    func updatesWidthFloorWhenSameHeightIdealWidthGrows() async throws {
        let model = DynamicMinimumWidthModel(idealWidth: 260)
        let (window, hostingView) = dynamicMinimumWidthWindow(
            model: model,
            toolbarIdentifier: "DynamicWidthGrowthTests"
        )
        try await settleBridge(
            in: hostingView,
            window: window,
            expectedMinimumHeight: expectedMinimumHeight(
                in: window,
                reservedContentHeight: DynamicMinimumWidthContent.fixedHeight,
                additionalContentHeight: 0
            )
        )
        let initialSize = try #require(window.contentView?.bounds.size)
        let initialMinimumWidth = window.contentMinSize.width
        let initialFrameHeight = window.frame.height
        let expectedMinimumWidth = 420 + contentLayoutInsetWidth(in: window)

        #expect(initialMinimumWidth >= DynamicMinimumWidthContent.minimumWidth - 0.5)

        model.idealWidth = 420
        hostingView.layoutSubtreeIfNeeded()
        await Task.yield()
        hostingView.layoutSubtreeIfNeeded()
        await Task.yield()
        let updatedSize = try await settleDynamicMinimum(
            in: hostingView,
            window: window,
            expectedMinimumWidth: expectedMinimumWidth,
            expectedCurrentContentWidth: expectedMinimumWidth,
            expectedContentHeight: initialSize.height,
            expectedFrameHeight: initialFrameHeight
        )

        #expect(abs(window.contentMinSize.width - expectedMinimumWidth) < 0.5)
        #expect(updatedSize.width >= expectedMinimumWidth - 0.5)
        #expect(abs(updatedSize.height - initialSize.height) < 0.5)
        #expect(abs(window.frame.height - initialFrameHeight) < 0.5)

        try await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func returnsWidthFloorToTheStableSwiftUIMinimum() async throws {
        let model = DynamicMinimumWidthModel(idealWidth: 260)
        let (window, hostingView) = dynamicMinimumWidthWindow(
            model: model,
            toolbarIdentifier: "DynamicWidthReturnTests"
        )
        try await settleBridge(
            in: hostingView,
            window: window,
            expectedMinimumHeight: expectedMinimumHeight(
                in: window,
                reservedContentHeight: DynamicMinimumWidthContent.fixedHeight,
                additionalContentHeight: 0
            )
        )
        let initialSize = try #require(window.contentView?.bounds.size)
        let initialMinimumWidth = window.contentMinSize.width
        let initialFrameHeight = window.frame.height
        let widerMinimumWidth = 420 + contentLayoutInsetWidth(in: window)

        model.idealWidth = 420
        hostingView.layoutSubtreeIfNeeded()
        await Task.yield()
        let widerSize = try await settleDynamicMinimum(
            in: hostingView,
            window: window,
            expectedMinimumWidth: widerMinimumWidth,
            expectedCurrentContentWidth: widerMinimumWidth,
            expectedContentHeight: initialSize.height,
            expectedFrameHeight: initialFrameHeight
        )

        model.idealWidth = 260
        hostingView.layoutSubtreeIfNeeded()
        await Task.yield()
        let returnedSize = try await settleDynamicMinimum(
            in: hostingView,
            window: window,
            expectedMinimumWidth: initialMinimumWidth,
            expectedCurrentContentWidth: widerSize.width,
            expectedContentHeight: initialSize.height,
            expectedFrameHeight: initialFrameHeight
        )

        #expect(abs(window.contentMinSize.width - initialMinimumWidth) < 0.5)
        #expect(window.contentMinSize.width < widerMinimumWidth - 0.5)
        #expect(window.contentMinSize.width >= DynamicMinimumWidthContent.minimumWidth - 0.5)
        #expect(returnedSize.width >= widerSize.width - 0.5)
        #expect(abs(returnedSize.height - initialSize.height) < 0.5)
        #expect(abs(window.frame.height - initialFrameHeight) < 0.5)

        try await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func repeatedSameHeightUpdatesPreserveTheSwiftUIMinimum() async throws {
        let model = DynamicMinimumWidthModel(idealWidth: 260)
        let (window, hostingView) = dynamicMinimumWidthWindow(
            model: model,
            toolbarIdentifier: "RepeatedUnderFloorResizeTests"
        )
        try await settleBridge(
            in: hostingView,
            window: window,
            expectedMinimumHeight: expectedMinimumHeight(
                in: window,
                reservedContentHeight: DynamicMinimumWidthContent.fixedHeight,
                additionalContentHeight: 0
            )
        )
        let initialSize = try #require(window.contentView?.bounds.size)
        let swiftUIMinimumWidth = window.contentMinSize.width
        let initialFrameHeight = window.frame.height
        let underFloorIdealWidths: [CGFloat] = [260, 280, 240, 290, 250, 270]

        for idealWidth in underFloorIdealWidths {
            model.idealWidth = idealWidth
            hostingView.layoutSubtreeIfNeeded()
            await Task.yield()

            let size = try await settleDynamicMinimum(
                in: hostingView,
                window: window,
                expectedMinimumWidth: swiftUIMinimumWidth,
                expectedCurrentContentWidth: swiftUIMinimumWidth,
                expectedContentHeight: initialSize.height,
                expectedFrameHeight: initialFrameHeight
            )

            #expect(window.contentMinSize.width >= swiftUIMinimumWidth - 0.5)
            #expect(size.width >= swiftUIMinimumWidth - 0.5)
            #expect(abs(size.height - initialSize.height) < 0.5)
            #expect(abs(window.frame.height - initialFrameHeight) < 0.5)
        }

        try await close(window, hostingView: hostingView)
    }

    @MainActor
    @Test
    func transientUnderFloorResizeDoesNotInstallARequiredWidthConflict() async throws {
        let (window, hostingView) = responsiveLayoutWindow(contentWidth: 700)
        let initialSize = try await settledMinimumSize(of: window, contentWidth: 700)
        let initialFrameHeight = window.frame.height

        _ = try await settledSizeAfterHorizontalResize(
            of: window,
            contentWidth: 300,
            preservingContentHeight: initialSize.height,
            preservingFrameHeight: initialFrameHeight
        )

        let layoutGuide = try #require(window.contentLayoutGuide as? NSLayoutGuide)
        let contentView = try #require(window.contentView)
        let constraintOwner = try #require(layoutGuide.owningView)
        let minimumWidthConstraint = try #require(
            constraintOwner.constraints.first { constraint in
                constraint.relation == .greaterThanOrEqual
                    && constraint.firstItem as AnyObject? === layoutGuide
                    && abs(constraint.constant - 334) < 0.5
            }
        )

        #expect(minimumWidthConstraint.priority < .required)
        #expect(window.contentMinSize.width >= 334 - 0.5)
        #expect(contentView.bounds.width >= 334 - 0.5)
        #expect(abs(contentView.bounds.height - initialSize.height) < 0.5)
        #expect(abs(window.frame.height - initialFrameHeight) < 0.5)

        try await close(window, hostingView: hostingView)
    }

}
