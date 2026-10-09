import SwiftUI

/// The current information, progress, or status content beside a discovery picker.
enum DiscoveryAccessoryPresentation {

    /// Visual details for a discovery result that needs an explanation popover.
    struct Status {
        let symbol: String
        let color: Color
        let label: String
    }

    case information
    case progress(accessibilityLabel: String)
    case status(Status)

}
