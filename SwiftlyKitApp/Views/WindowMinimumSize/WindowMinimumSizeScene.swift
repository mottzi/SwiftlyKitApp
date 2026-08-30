import SwiftUI

extension Scene {

    /// Gives new windows a fixed width and asks `.contentMinSize` to resolve their live minimum height.
    /// Restored windows keep their saved size because SwiftUI ignores the default during restoration.
    func defaultSizeAtMinimumHeight(width: CGFloat) -> some Scene {
        defaultSize(width: width, height: 1)
    }

}
