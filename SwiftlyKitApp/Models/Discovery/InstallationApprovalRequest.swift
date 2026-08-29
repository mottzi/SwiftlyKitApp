import SwiftlyKit

/// One complete environment installation that needs the user's approval.
struct InstallationApprovalRequest: Equatable {

    let message: String

    init(
        swiftVersion: SwiftVersion,
        staticLinuxSDKVersion: String,
        requiredComponents: [PreparationComponent]
    ) {
        let componentNames = requiredComponents.map { component in
            switch component {
                case .swiftly: "Swiftly"
                case .toolchain: "Swift \(swiftVersion)"
                case .staticLinuxSDK: "Static Linux SDK \(staticLinuxSDKVersion)"
            }
        }

        message = "Do you want to install \(Self.formattedList(componentNames))?"
    }

    private static func formattedList(_ names: [String]) -> String {
        switch names.count {
            case 0:
                return "the required Swift components"
            case 1:
                return names[0]
            case 2:
                return "\(names[0]) and \(names[1])"
            default:
                return names.dropLast().joined(separator: ", ")
                    + ", and \(names[names.count - 1])"
        }
    }

}
