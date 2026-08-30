import SwiftUI

struct PackageConfigurator: View {

    @Environment(BuildOptions.self) private var buildOptions

    @State private var presentedPopover: PresentedBuildOptionPopover?

    var body: some View {
        @Bindable var buildOptions = buildOptions

        AdaptiveGrid {
            buildOptionField("Product", layoutReference: .firstField) {
                ProductControl(
                    infoPopoverPresented: isPopoverPresented(.info(.product)),
                    statusPopoverPresented: isPopoverPresented(.productDiscoveryStatus),
                    onRetry: requestProductDiscoveryRetry
                )
            }

            buildOptionField("Target", layoutReference: .secondField) {
                TargetControl(
                    target: $buildOptions.target,
                    infoPopoverPresented: isPopoverPresented(.info(.target))
                )
            }

            buildOptionField("Configuration") {
                BuildConfigurationControl(
                    configuration: $buildOptions.configuration,
                    infoPopoverPresented: isPopoverPresented(.info(.configuration))
                )
            }

            buildOptionField("Swift") {
                SwiftToolchainControl(
                    infoPopoverPresented: isPopoverPresented(.info(.swift)),
                    statusPopoverPresented: isPopoverPresented(.toolchainDiscoveryStatus),
                    onRetry: requestToolchainDiscoveryRetry
                )
            }

            buildOptionField("Strip Binary") {
                StripBinaryControl(
                    isEnabled: $buildOptions.stripBinary,
                    infoPopoverPresented: isPopoverPresented(.info(.stripBinary))
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .disabled(buildOptions.buildWorkflow.isRunning)
        .overlayPreferenceValue(BuildOptionLabelBoundsPreferenceKey.self) { bounds in
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: PackageSection.LayoutMode.PreferenceKey.self,
                        value: layoutMode(for: bounds, in: proxy)
                    )
            }
        }
    }

}

extension PackageConfigurator {

    /// Closes the contextual popover before the existing discovery task starts again.
    private func requestProductDiscoveryRetry() {
        presentedPopover = nil
        buildOptions.productDiscovery.requestRetry()
    }

    /// Closes the contextual popover before compatible toolchains are discovered again.
    private func requestToolchainDiscoveryRetry() {
        presentedPopover = nil
        buildOptions.toolchainDiscovery.requestRetry()
    }

    /// Binds one contextual anchor to the section's single presented-popover state.
    private func isPopoverPresented(_ popover: PresentedBuildOptionPopover) -> Binding<Bool> {
        Binding(
            get: { presentedPopover == popover },
            set: { isPresented in
                if isPresented {
                    presentedPopover = popover
                } else if presentedPopover == popover {
                    presentedPopover = nil
                }
            }
        )
    }

    /// Emits exactly two direct children for `AdaptiveGrid`: a label followed by its control.
    @ViewBuilder
    private func buildOptionField<Control: View>(
        _ title: LocalizedStringKey,
        layoutReference: BuildOptionLayoutReference? = nil,
        control: () -> Control
    ) -> some View {

        Text(title)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .anchorPreference(
                key: BuildOptionLabelBoundsPreferenceKey.self,
                value: .bounds
            ) { bounds in
                guard let layoutReference else { return [:] }
                return [layoutReference: bounds]
            }

        control()
    }

    /// Reads the grid's placement of its first two fields as the selected column arrangement.
    private func layoutMode(
        for bounds: [BuildOptionLayoutReference: Anchor<CGRect>],
        in proxy: GeometryProxy
    ) -> PackageSection.LayoutMode? {

        guard
            let firstField = bounds[.firstField],
            let secondField = bounds[.secondField]
        else { return nil }

        let firstOriginY = proxy[firstField].minY
        let secondOriginY = proxy[secondField].minY

        return abs(firstOriginY - secondOriginY) < Self.sharedRowTolerance
            ? .twoColumns
            : .oneColumn
    }

}

/// Field labels used to identify the grid's first visual row.
private enum BuildOptionLayoutReference: Hashable {

    case firstField
    case secondField

}

/// Collects field-label bounds after `AdaptiveGrid` places them.
private struct BuildOptionLabelBoundsPreferenceKey: PreferenceKey {

    static let defaultValue: [BuildOptionLayoutReference: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [BuildOptionLayoutReference: Anchor<CGRect>],
        nextValue: () -> [BuildOptionLayoutReference: Anchor<CGRect>]
    ) {

        value.merge(nextValue()) { _, latest in latest }
    }

}

/// The one contextual popover that can be presented by the package configurator.
private enum PresentedBuildOptionPopover: Equatable {

    case info(BuildOptionInfo)
    case productDiscoveryStatus
    case toolchainDiscoveryStatus

}

extension PackageConfigurator {

    private static let sharedRowTolerance: CGFloat = 1

}
