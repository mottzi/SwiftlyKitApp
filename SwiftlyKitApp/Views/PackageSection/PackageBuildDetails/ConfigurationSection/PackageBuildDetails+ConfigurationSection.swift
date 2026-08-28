import SwiftUI
import SwiftlyKit

extension PackageBuildDetails {

    struct ConfigurationSection: View {

        @Environment(BuildOptions.self) private var buildOptions

        @State private var presentedPopover: PresentedConfigurationPopover?

        var body: some View {
            @Bindable var buildOptions = buildOptions

            LabelControlGrid {
                configurationField("Product") {
                    ProductControl(
                        infoPopoverPresented: isPopoverPresented(.info(.product)),
                        statusPopoverPresented: isPopoverPresented(.productDiscoveryStatus),
                        onRetry: requestProductDiscoveryRetry
                    )
                }

                configurationField("Target") {
                    TargetConfigurationControl(
                        target: $buildOptions.target,
                        infoPopoverPresented: isPopoverPresented(.info(.target))
                    )
                }

                configurationField("Configuration") {
                    BuildConfigurationControl(
                        configuration: $buildOptions.configuration,
                        infoPopoverPresented: isPopoverPresented(.info(.configuration))
                    )
                }

                configurationField("Swift") {
                    SwiftToolchainControl(
                        toolchain: $buildOptions.toolchain,
                        infoPopoverPresented: isPopoverPresented(.info(.swift))
                    )
                }

                configurationField("Strip Binary") {
                    StripBinaryControl(
                        isEnabled: $buildOptions.stripBinary,
                        infoPopoverPresented: isPopoverPresented(.info(.stripBinary))
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

    }

}

extension PackageBuildDetails.ConfigurationSection {

    /// Closes the contextual popover before the existing discovery task starts again.
    private func requestProductDiscoveryRetry() {
        presentedPopover = nil
        buildOptions.requestProductDiscoveryRetry()
    }

    /// Binds one contextual anchor to the section's single presented-popover state.
    private func isPopoverPresented(_ popover: PresentedConfigurationPopover) -> Binding<Bool> {
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
    private func configurationField<Control: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder control: () -> Control
    ) -> some View {

        Text(title)
            .font(.subheadline)
            .foregroundStyle(.secondary)

        control()
    }

}

/// The one contextual popover that can be presented by the configuration section.
private enum PresentedConfigurationPopover: Equatable {

    case info(ConfigurationOption)
    case productDiscoveryStatus

}
