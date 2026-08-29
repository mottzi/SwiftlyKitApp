import SwiftUI

/// Reduces visual prominence while preserving the content's identity and layout.
struct DeemphasisedContentModifier: ViewModifier {

    let isDeemphasised: Bool

    func body(content: Content) -> some View {
        content
            .saturation(isDeemphasised ? Self.saturation : 1)
            .opacity(isDeemphasised ? Self.opacity : 1)
    }

}

extension DeemphasisedContentModifier {

    private static let saturation = 0.0
    private static let opacity = 0.65

}

extension View {

    /// Reduces this view's visual prominence when `condition` is true.
    func deemphasiseContent(when condition: Bool) -> some View {
        modifier(DeemphasisedContentModifier(isDeemphasised: condition))
    }

}
