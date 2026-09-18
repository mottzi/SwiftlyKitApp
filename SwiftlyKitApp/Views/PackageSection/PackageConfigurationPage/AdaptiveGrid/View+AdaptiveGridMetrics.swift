import SwiftUI

extension View {

    /// Publishes an `AdaptiveGrid`'s width-recommended arrangement and alternate one-column height.
    func publishesAdaptiveGridMetrics() -> some View {
        overlay(alignment: .adaptiveGridFirstFieldRow) {
            adaptiveGridMetricMarker(.firstFieldRow)
        }
        .overlay(alignment: .adaptiveGridSecondFieldRow) {
            adaptiveGridMetricMarker(.secondFieldRow)
        }
        .overlay(alignment: .adaptiveGridOneColumnBottom) {
            adaptiveGridMetricMarker(.oneColumnBottom)
        }
    }

    /// Calls `action` when the width-recommended arrangement of a descendant `AdaptiveGrid` changes.
    func onAdaptiveGridArrangementChange(
        _ action: @escaping (AdaptiveGridArrangement) -> Void
    ) -> some View {
        modifier(AdaptiveGridArrangementObserver(action: action))
    }

    /// Reserves the reported alternate grid height in the containing window.
    func reservesAdaptiveGridHeightForWindow(
        addingBottom additionalHeight: CGFloat
    ) -> some View {
        overlayPreferenceValue(AdaptiveGridMetricAnchorPreferenceKey.self) { anchors in
            GeometryReader { proxy in
                if let anchor = anchors[.oneColumnBottom] {
                    Color.clear.windowMinimumHeightReservation(
                        proxy[anchor].maxY + additionalHeight
                    )
                }
            }
        }
    }

    private func adaptiveGridMetricMarker(
        _ metric: AdaptiveGridMetric
    ) -> some View {
        Color.clear
            .frame(width: 0, height: 0)
            .anchorPreference(
                key: AdaptiveGridMetricAnchorPreferenceKey.self,
                value: .bounds
            ) { [metric: $0] }
    }

}

/// Resolves private grid markers and exposes only the semantic arrangement.
private struct AdaptiveGridArrangementObserver: ViewModifier {

    let action: (AdaptiveGridArrangement) -> Void

    func body(content: Content) -> some View {
        content
            .overlayPreferenceValue(AdaptiveGridMetricAnchorPreferenceKey.self) { anchors in
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: AdaptiveGridArrangementPreferenceKey.self,
                        value: arrangement(for: anchors, in: proxy)
                    )
                }
            }
            .onPreferenceChange(AdaptiveGridArrangementPreferenceKey.self) {
                guard let arrangement = $0 else { return }
                action(arrangement)
            }
    }

    private func arrangement(
        for anchors: [AdaptiveGridMetric: Anchor<CGRect>],
        in proxy: GeometryProxy
    ) -> AdaptiveGridArrangement? {
        guard
            let firstField = anchors[.firstFieldRow],
            let secondField = anchors[.secondFieldRow]
        else { return nil }

        let firstOriginY = proxy[firstField].minY
        let secondOriginY = proxy[secondField].minY

        return abs(firstOriginY - secondOriginY) < Self.rowOriginTolerance
            ? .twoColumns
            : .oneColumn
    }

    private static let rowOriginTolerance: CGFloat = 1

}
