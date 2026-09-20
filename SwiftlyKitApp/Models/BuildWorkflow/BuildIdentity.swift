import SwiftlyKit

/// Immutable choices that produced one build result.
struct BuildIdentity: Equatable {

    let product: String
    let target: BuildTarget
    let configuration: BuildConfiguration
    let swiftVersion: SwiftVersion
    let stripBinary: Bool

    /// Compact description of the executable and its build environment.
    var summary: String {
        "\(product) · \(target.displayName) · \(configuration.displayName) · Swift \(swiftVersion)"
    }

}
