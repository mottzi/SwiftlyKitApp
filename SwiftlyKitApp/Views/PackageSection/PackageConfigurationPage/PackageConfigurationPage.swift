import AppKit
import SwiftUI

struct PackageConfigurationPage: View {

    let onIdealHeightChange: (CGFloat) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PackageHeader()
                .padding(.horizontal, Self.horizontalPadding)
                .padding(.top, Self.verticalPadding)
                .padding(.bottom, Self.spacing)
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
                .background(
                    Color(nsColor: .textBackgroundColor)
                        .opacity(Self.configurationBackgroundOpacity)
                )
        }
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.height
        } action: { height in
            onIdealHeightChange(height)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .sectionSurface()
    }

}

extension PackageConfigurationPage {

    private static let spacing: CGFloat = 14
    private static let horizontalPadding: CGFloat = 16
    private static let verticalPadding: CGFloat = 12
    private static let dividerOpacity = 0.55
    private static let configurationBackgroundOpacity = 0.5

}
