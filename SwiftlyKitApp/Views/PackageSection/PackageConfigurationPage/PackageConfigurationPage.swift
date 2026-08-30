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
                .anchorPreference(
                    key: ConfigurationBackgroundTopPreferenceKey.self,
                    value: .bounds
                ) { $0 }
            PackageConfigurator()
                .padding(.leading, Self.horizontalPadding)
                .padding(.trailing, ConfigurationAccessoryMetrics.spacing)
                .padding(.top, Self.spacing)
                .padding(.bottom, Self.verticalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.height
        } action: { height in
            onIdealHeightChange(height)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .backgroundPreferenceValue(ConfigurationBackgroundTopPreferenceKey.self) { dividerBounds in
            GeometryReader { geometry in
                if let dividerBounds {
                    let configurationOriginY = geometry[dividerBounds].maxY

                    Color(nsColor: .textBackgroundColor)
                        .opacity(Self.configurationBackgroundOpacity)
                        .frame(
                            width: geometry.size.width,
                            height: max(geometry.size.height - configurationOriginY, 0)
                        )
                        .offset(y: configurationOriginY)
                }
            }
        }
        .sectionSurface()
    }

}

private struct ConfigurationBackgroundTopPreferenceKey: PreferenceKey {

    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(
        value: inout Anchor<CGRect>?,
        nextValue: () -> Anchor<CGRect>?
    ) {
        value = nextValue() ?? value
    }

}

#Preview {
    PackageConfigurationPage(onIdealHeightChange: { _ in })
        .environment(PackageModel())
        .environment(BuildOptions())
        .frame(
            width: SwiftlyKitApp.defaultWindowSize.width,
            height: SwiftlyKitApp.defaultWindowSize.height
        )
}

extension PackageConfigurationPage {

    private static let spacing: CGFloat = 14
    private static let horizontalPadding: CGFloat = 16
    private static let verticalPadding: CGFloat = 12
    private static let dividerOpacity = 0.55
    private static let configurationBackgroundOpacity = 0.5

}
