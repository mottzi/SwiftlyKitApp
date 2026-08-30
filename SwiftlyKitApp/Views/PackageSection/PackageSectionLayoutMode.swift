import SwiftUI

/// Form arrangement shared by the package configuration and package picker label.
enum PackageSectionLayoutMode: Hashable {

    case oneColumn
    case twoColumns

}

/// Carries the configuration form's selected arrangement to `PackageSection`.
struct PackageSectionLayoutModePreferenceKey: PreferenceKey {

    static let defaultValue: PackageSectionLayoutMode? = nil

    static func reduce(
        value: inout PackageSectionLayoutMode?,
        nextValue: () -> PackageSectionLayoutMode?
    ) {

        value = nextValue() ?? value
    }

}
