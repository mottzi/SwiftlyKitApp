/// Build options that have contextual explanations.
enum BuildOptionInfo: Equatable {
    
    case product
    case target
    case configuration
    case swift
    case stripBinary
    
}

extension BuildOptionInfo {

    /// Short label used as the information popover title.
    var title: String {
        switch self {
            case .product: "Product"
            case .target: "Target"
            case .configuration: "Configuration"
            case .swift: "Swift"
            case .stripBinary: "Strip Binary"
        }
    }

    /// Explanation shown by the information popover.
    var message: String {
        switch self {
            case .product:
                "Choose the executable product SwiftPM should build. " +
                "Available products are discovered for the selected target and Swift toolchain."
            case .target:
                "Choose the Linux architecture for the output executable. Changing the target refreshes available products."
            case .configuration:
                "Choose the SwiftPM build configuration used for the executable."
            case .swift:
                "Choose the Swift toolchain used to prepare the build environment. " +
                "Automatic selects a compatible Swift release."
            case .stripBinary:
                "Strip symbols from the finished executable to reduce its size."
        }
    }

    /// Accessibility label for the information button.
    var accessibilityLabel: String {
        "\(title) information"
    }

}
