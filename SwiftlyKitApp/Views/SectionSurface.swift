import SwiftUI

/// Standard rounded surface shared by the app's primary sections.
struct SectionSurface: ViewModifier {

    func body(content: Content) -> some View {
        content
            .clipShape(Self.shape)
            .background {
                Self.shape
                    .fill(.quaternary.opacity(Self.fillOpacity))
            }
            .overlay {
                Self.shape.strokeBorder(
                    Color.primary.opacity(Self.borderOpacity),
                    lineWidth: Self.borderWidth
                )
                .allowsHitTesting(false)
            }
    }

}

extension SectionSurface {

    private static let shape = RoundedRectangle(cornerRadius: cornerRadius)

    private static let cornerRadius: CGFloat = 12
    private static let fillOpacity = 0.38
    private static let borderOpacity = 0.06
    private static let borderWidth: CGFloat = 1

}

extension View {

    func sectionSurface() -> some View {
        modifier(SectionSurface())
    }

}
