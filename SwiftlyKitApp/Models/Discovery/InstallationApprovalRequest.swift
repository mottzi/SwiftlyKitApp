import SwiftlyKit

/// One complete environment installation that needs the user's approval.
struct InstallationApprovalRequest: Equatable {

    let message: String

    init(
        swiftVersion: SwiftVersion,
        staticLinuxSDKVersion: String,
        requiredComponents: [PreparationComponent]
    ) {
        let componentNames = requiredComponents.compactMap { component -> String? in
            switch component {
                case .swiftlyUpdate: nil
                case .swiftly: "Swiftly"
                case .toolchain: "Swift \(swiftVersion)"
                case .staticLinuxSDK: "Static Linux SDK \(staticLinuxSDKVersion)"
            }
        }

        if requiredComponents.contains(.swiftlyUpdate) {
            message = "Update your existing Swiftly installation if needed, then install "
                + "\(Self.formattedList(componentNames))?"
        } else {
            message = "Do you want to install \(Self.formattedList(componentNames))?"
        }
    }

}

extension InstallationApprovalRequest {

    private static func formattedList(_ names: [String]) -> String {
        switch names.count {
            case 0: "the required Swift components"
            case 1: names[0]
            case 2: "\(names[0]) and \(names[1])"
            default: names.dropLast().joined(separator: ", ") + ", and \(names[names.count - 1])"
        }
    }

}
