import SwiftlyKit

/// Prepared environment and executable selected for the next build.
struct PreparedPackage {

    let environment: LocalBuildEnvironment
    let selectedProduct: ExecutableProduct

}
