import SwiftUI

enum AdaptiveGridMetric: Hashable {

    case firstFieldRow
    case secondFieldRow
    case oneColumnBottom

}

struct AdaptiveGridMetricAnchorPreferenceKey: PreferenceKey {

    static let defaultValue: [AdaptiveGridMetric: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [AdaptiveGridMetric: Anchor<CGRect>],
        nextValue: () -> [AdaptiveGridMetric: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { _, latest in latest }
    }

}

struct AdaptiveGridArrangementPreferenceKey: PreferenceKey {

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
