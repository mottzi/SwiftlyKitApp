import SwiftUI

/// Standard background shared by the app's primary sections.
struct SectionSurface: View {

    var body: some View {
        RoundedRectangle(cornerRadius: Self.cornerRadius)
            .fill(.quaternary.opacity(Self.fillOpacity))
            .strokeBorder(
                Color.primary.opacity(Self.borderOpacity),
                lineWidth: Self.borderWidth
            )
    }

}

extension SectionSurface {

    private static let cornerRadius: CGFloat = 12
    private static let fillOpacity = 0.38
    private static let borderOpacity = 0.06
    private static let borderWidth: CGFloat = 1

}
