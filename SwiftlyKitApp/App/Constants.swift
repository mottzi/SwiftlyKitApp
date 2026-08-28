import SwiftUI

enum Constants {

    // Window
    static let windowSize = CGSize(width: 500, height: 300)
    static let minWindowWidth: CGFloat = 300

    // App layout
    static let appSpacing: CGFloat = 10
    static let appHorizontalPadding: CGFloat = 12
    static let appTopPadding: CGFloat = 2
    static let appBottomPadding: CGFloat = 12
    static let minBuildSectionHeight: CGFloat = 80
    static let windowHeightAllowance = appSpacing
        + minBuildSectionHeight
        + appTopPadding
        + appBottomPadding

    // Section surface
    static let sectionRadius: CGFloat = 12
    static let sectionFillOpacity = 0.38
    static let sectionBorderOpacity = 0.06
    static let sectionBorderWidth: CGFloat = 1

    // Package pager
    static let pageSpacing: CGFloat = 10
    static let pageTrailingInset: CGFloat = 38
    static let inactiveSaturation = 0.0
    static let inactiveOpacity = 0.65
    static let inactiveDetailsScale: CGFloat = 0.9
    static let inactiveDetailsRotation = Angle.degrees(0.8)
    static let inactiveDetailsOffset = CGSize(width: 2, height: -2)

    // Package details
    static let detailsSpacing: CGFloat = 14
    static let detailsHorizontalPadding: CGFloat = 16
    static let detailsVerticalPadding: CGFloat = 12
    static let detailsDividerOpacity = 0.55
    static let headerSpacing: CGFloat = 12
    static let headerIconLength: CGFloat = 26
    static let headerTextSpacing: CGFloat = 2
    static let pathFontSize: CGFloat = 11
    static let headerLineLimit = 1
    static let headerTextPriority = -1.0
    static let menuButtonLength: CGFloat = 28

    // Configuration grid
    nonisolated static let configLabelSpacing: CGFloat = 12
    nonisolated static let configColumnSpacing: CGFloat = 24
    nonisolated static let configRowSpacing: CGFloat = 12

    // Configuration accessories
    static let configurationAccessoryLength: CGFloat = 20
    static let configurationAccessorySpacing: CGFloat = 6
    static let configurationAccessoryTrailingPadding: CGFloat = configurationAccessorySpacing
    static let configurationInfoPopoverWidth: CGFloat = 280
    static let productDiscoveryPopoverWidth: CGFloat = 320

    // Package picker
    static let pickerRadius: CGFloat = 12
    static let pickerLabelSpacing: CGFloat = 16
    static let pickerIconLength: CGFloat = 80
    static let pickerTitleLineLimit = 1
    static let pickerHoverRotation = Angle.degrees(4)
    static let pickerTargetedScale: CGFloat = 1.10
    static let pickerPressedScale: CGFloat = 0.98
    static let pickerPressedFillOpacity = 0.10
    static let pickerTargetedFillOpacity = 0.12
    static let pickerHoverFillOpacity = 0.04
    static let pickerIdleDashPattern: [CGFloat] = [8, 6]
    static let pickerTargetedDashPattern: [CGFloat] = [10, 6]
    static let pickerIdleLineWidth: CGFloat = 2
    static let pickerTargetedLineWidth: CGFloat = 3
    static let pickerHoverDashPhase: CGFloat = -6
    static let pickerActiveDashPhase: CGFloat = -12

}
