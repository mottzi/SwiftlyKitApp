import SwiftUI

// MARK: - Mock State Models (used by ProjectCard)

public enum MockEnvironmentStatus: Equatable, Sendable {
    case ready(description: String)
    case installRequired(toolchain: String, sdk: String)
    case installing(toolchain: String, progress: Double)
}

// MARK: - Environment Values for interactive states

extension EnvironmentValues {
    @Entry var isHovering = false
    @Entry var isPressed = false
    @Entry var isDropTargeted = false
}
