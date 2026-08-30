import AppKit
import SwiftUI

struct PackageConfigurationPage: View {

    let onIdealHeightChange: (CGFloat) -> Void

    init(onIdealHeightChange: @escaping (CGFloat) -> Void = { _ in }) {
        self.onIdealHeightChange = onIdealHeightChange
    }

    var body: some View {
        IdealHeightReportingLayout {
            VStack(alignment: .leading, spacing: 0) {
                PackageHeader()
                Divider()
                    .opacity(Self.dividerOpacity)
                PackageConfigurator()
                    .padding(.leading, Self.horizontalPadding)
                    .padding(.trailing, ConfigurationAccessoryMetrics.spacing)
                    .padding(.top, Self.spacing)
                    .padding(.bottom, Self.verticalPadding)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
            }
            .frame(maxHeight: .infinity, alignment: .top)

            Color.clear
                .onGeometryChange(for: CGFloat.self) { geometry in
                    geometry.size.height
                } action: { height in
                    onIdealHeightChange(height)
                }
        }
        .background {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: SectionHeaderMetrics.height)
                Divider()
                    .hidden()
                Color(nsColor: .textBackgroundColor)
                    .opacity(Self.configurationBackgroundOpacity)
            }
        }
        .sectionSurface()
    }

}

/// Measures the page without a height proposal while rendering it at the presented height.
private struct IdealHeightReportingLayout {
}

nonisolated extension IdealHeightReportingLayout: Layout {

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard let content = subviews.first else { return .zero }

        let idealSize = content.sizeThatFits(
            ProposedViewSize(width: finite(proposal.width), height: nil)
        )

        return CGSize(
            width: resolved(proposal.width, fallback: idealSize.width),
            height: resolved(proposal.height, fallback: idealSize.height)
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard let content = subviews.first else { return }

        content.place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height)
        )

        guard subviews.count > 1 else { return }

        let idealHeight = content.sizeThatFits(
            ProposedViewSize(width: bounds.width, height: nil)
        ).height
        subviews[1].place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: ProposedViewSize(width: 0, height: idealHeight)
        )
    }

    private func finite(_ proposedValue: CGFloat?) -> CGFloat? {
        guard let proposedValue, proposedValue.isFinite else { return nil }
        return max(proposedValue, 0)
    }

    private func resolved(_ proposedValue: CGFloat?, fallback: CGFloat) -> CGFloat {
        finite(proposedValue) ?? fallback
    }

}

extension PackageConfigurationPage {

    private static let spacing: CGFloat = 14
    private static let horizontalPadding: CGFloat = 16
    private static let verticalPadding: CGFloat = 12
    private static let dividerOpacity = 0.55
    private static let configurationBackgroundOpacity = 0.5

}
