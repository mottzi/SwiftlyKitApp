import SwiftUI

/// Layout markers used to report column arrangement and reserve one-column height.
enum AdaptiveGridMetric: Hashable {

    case firstFieldRow
    case secondFieldRow
    case oneColumnBottom

}

/// Descendant grid anchors collected for arrangement and window-height measurements.
struct AdaptiveGridMetricAnchorPreferenceKey: PreferenceKey {

    static func reduce(
        value: inout [AdaptiveGridMetric: Anchor<CGRect>],
        nextValue: () -> [AdaptiveGridMetric: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { _, latest in latest }
    }

    static let defaultValue: [AdaptiveGridMetric: Anchor<CGRect>] = [:]

}

/// Latest available column arrangement reported by a descendant grid.
struct AdaptiveGridArrangementPreferenceKey: PreferenceKey {

    static func reduce(value: inout AdaptiveGridArrangement?, nextValue: () -> AdaptiveGridArrangement?) {
        value = nextValue() ?? value
    }

    static let defaultValue: AdaptiveGridArrangement? = nil

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

    nonisolated static let adaptiveGridFirstFieldRow = Alignment(
        horizontal: .leading,
        vertical: .adaptiveGridFirstFieldRow
    )
    nonisolated static let adaptiveGridSecondFieldRow = Alignment(
        horizontal: .leading,
        vertical: .adaptiveGridSecondFieldRow
    )
    nonisolated static let adaptiveGridOneColumnBottom = Alignment(
        horizontal: .leading,
        vertical: .adaptiveGridOneColumnBottom
    )

}
