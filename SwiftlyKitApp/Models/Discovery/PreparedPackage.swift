import SwiftlyKit

/// Root-manifest configuration for a build that will validate dependencies before compilation.
struct PreparedPackage {

    let environment: LocalBuildEnvironment
    let selectedProduct: ExecutableProduct

}
