import SwiftUI

/// Set to `true` to make animations 5x slower for debugging and inspecting transitions.
public var DEBUG_SLOW_ANIMATIONS: Bool = true

extension Animation {

    /// Applies debug speed scaling (0.2x speed / 5x duration when `DEBUG_SLOW_ANIMATIONS` is true).
    public func debugScaled() -> Animation {
        DEBUG_SLOW_ANIMATIONS ? self.speed(0.2) : self
    }

    /// Standard spring animation with debug speed scaling.
    public static func appSpring(
        response: Double = 0.45,
        dampingFraction: Double = 0.75,
        blendDuration: Double = 0
    ) -> Animation {
        .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
            .debugScaled()
    }

}

/// Runs a state change with debug-scaled animation.
public func withAppAnimation<Result>(
    _ animation: Animation = .appSpring(),
    _ body: () throws -> Result
) rethrows -> Result {
    try withAnimation(animation.debugScaled(), body)
}
