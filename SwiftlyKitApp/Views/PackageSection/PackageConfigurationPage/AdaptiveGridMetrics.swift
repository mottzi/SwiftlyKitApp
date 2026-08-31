import SwiftUI

/// Arrangement selected by `AdaptiveGrid` after measuring its fields.
enum AdaptiveGridArrangement: Equatable, Sendable {

    case oneColumn
    case twoColumns

}

extension View {

    /// Publishes an `AdaptiveGrid`'s current arrangement and alternate one-column height.
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

    /// Calls `action` when a descendant `AdaptiveGrid` selects a different arrangement.
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

private enum AdaptiveGridMetric: Hashable {

    case firstFieldRow
    case secondFieldRow
    case oneColumnBottom

}

private struct AdaptiveGridMetricAnchorPreferenceKey: PreferenceKey {

    static let defaultValue: [AdaptiveGridMetric: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [AdaptiveGridMetric: Anchor<CGRect>],
        nextValue: () -> [AdaptiveGridMetric: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { _, latest in latest }
    }

}

private struct AdaptiveGridArrangementPreferenceKey: PreferenceKey {

    static let defaultValue: AdaptiveGridArrangement? = nil

    static func reduce(
        value: inout AdaptiveGridArrangement?,
        nextValue: () -> AdaptiveGridArrangement?
    ) {
        value = nextValue() ?? value
    }

}

private nonisolated struct AdaptiveGridFirstFieldRowAlignment: AlignmentID {

    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[VerticalAlignment.top]
    }

}

private nonisolated struct AdaptiveGridSecondFieldRowAlignment: AlignmentID {

    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[VerticalAlignment.top]
    }

}

private nonisolated struct AdaptiveGridOneColumnBottomAlignment: AlignmentID {

    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[VerticalAlignment.bottom]
    }

}

extension VerticalAlignment {

    nonisolated static let adaptiveGridFirstFieldRow = VerticalAlignment(
        AdaptiveGridFirstFieldRowAlignment.self
    )
    nonisolated static let adaptiveGridSecondFieldRow = VerticalAlignment(
        AdaptiveGridSecondFieldRowAlignment.self
    )
    nonisolated static let adaptiveGridOneColumnBottom = VerticalAlignment(
        AdaptiveGridOneColumnBottomAlignment.self
    )

}

extension Alignment {

    fileprivate nonisolated static let adaptiveGridFirstFieldRow = Alignment(
        horizontal: .leading,
        vertical: .adaptiveGridFirstFieldRow
    )
    fileprivate nonisolated static let adaptiveGridSecondFieldRow = Alignment(
        horizontal: .leading,
        vertical: .adaptiveGridSecondFieldRow
    )
    fileprivate nonisolated static let adaptiveGridOneColumnBottom = Alignment(
        horizontal: .leading,
        vertical: .adaptiveGridOneColumnBottom
    )

}
