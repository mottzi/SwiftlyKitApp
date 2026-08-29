import SwiftUI

struct PackageConfigurator: View {

    @Environment(BuildOptions.self) private var buildOptions

    @State private var presentedPopover: PresentedBuildOptionPopover?

    var body: some View {
        @Bindable var buildOptions = buildOptions

        LabelControlGrid {
            buildOptionField("Product") {
                ProductControl(
                    infoPopoverPresented: isPopoverPresented(.info(.product)),
                    statusPopoverPresented: isPopoverPresented(.productDiscoveryStatus),
                    onRetry: requestProductDiscoveryRetry
                )
            }

            buildOptionField("Target") {
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

    /// Emits exactly two direct children for `LabelControlGrid`: a label followed by its control.
    @ViewBuilder
    private func buildOptionField<Control: View>(
        _ title: LocalizedStringKey,
        control: () -> Control
    ) -> some View {

        Text(title)
            .font(.subheadline)
            .foregroundStyle(.secondary)

        control()
    }

}

/// The one contextual popover that can be presented by the package configurator.
private enum PresentedBuildOptionPopover: Equatable {

    case info(BuildOptionInfo)
    case productDiscoveryStatus
    case toolchainDiscoveryStatus

}
