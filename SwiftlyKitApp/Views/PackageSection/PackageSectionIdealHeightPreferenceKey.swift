import SwiftUI

/// Carries the configuration page's intrinsic height before the pager stretches it.
struct PackageSectionIdealHeightPreferenceKey: PreferenceKey {

    static let defaultValue = CGFloat.zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }

}
