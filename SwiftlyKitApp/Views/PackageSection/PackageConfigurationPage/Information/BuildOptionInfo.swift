/// Build options that have contextual explanations.
enum BuildOptionInfo {

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
                "Choose the Linux architecture for the output executable. "
                    + "Changing the target refreshes compatible Swift toolchains and products."
            case .configuration:
                "Release enables compiler optimizations for a faster executable. " +
                "Debug leaves optimizations off and includes debugging information, " +
                "making it easier to inspect code while debugging."
            case .swift:
                "Automatic uses the nearest .swift-version file in the package folder or its parent folders. " +
                "Without that file, it prefers the newest installed Swift version with its matching Linux SDK. " +
                "If no installed pair qualifies, it selects the newest official stable release. " +
                "The version must meet the package's Swift tools requirement and support the Linux target. " +
                "You can also choose an exact version."
            case .stripBinary:
                "Strip symbols from the finished executable to reduce its size."
        }
    }

    /// Accessibility label for the information button.
    var accessibilityLabel: String {
        "\(title) information"
    }

}
