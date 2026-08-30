# New windows starting at the dynamic minimum size

## Recommendation

Keep the existing `.windowMinimumSize(addingHeight:)` implementation and the package section's current layout behavior unchanged. For a new window, request a deliberately undersized default height and let the existing minimum-size machinery clamp or raise it to the current computed minimum:

```swift
WindowGroup {
    AppView()
}
.defaultSize(width: 500, height: 1)
.windowToolbarStyle(.unifiedCompact)
.windowResizability(.contentMinSize)
```

The `1` is not an approximation of the UI's height. It is an intentionally impossible default that delegates the final height to the minimum-size policy. Give it a descriptive constant or comment at the call site.

This is the smallest solution that satisfies the requirements:

- A genuinely new window starts at its current minimum instead of the historical hard-coded `420`-point default.
- A restored window keeps the person's saved size.
- The package section remains free to derive its height from whichever page is tallest, including a future taller picker.
- No AppKit type, restoration key, or window lifecycle concept enters the app scene or package views.
- No new custom `Layout`, measurement callback, timer, or saved-frame bookkeeping is required.

Treat this as a short experiment with a strict acceptance test, because the custom bridge publishes its final independent minimum after SwiftUI begins layout. The existing bridge already raises a window whose content is below that minimum, so the expected result is either an immediate system clamp or one correction during initial layout. Reject this version only if testing reveals a visible launch-size flash.

## Why this matches SwiftUI's contract

Apple says [`defaultSize(_:)`](https://developer.apple.com/documentation/swiftui/scene/defaultsize(_:)) supplies only the initial size of a new window. It also makes two guarantees directly relevant here:

1. During state restoration, the system restores the most recent size instead of the default.
2. A default outside the window's inherent resizable range is clamped into that range.

Apple says [`WindowResizability.contentMinSize`](https://developer.apple.com/documentation/swiftui/windowresizability/contentminsize) gives a window the minimum size of its content and no maximum. Asking for a height below that range therefore expresses "start at the minimum" without calculating or duplicating the minimum in the scene.

The repo's existing bridge remains justified. [`NSHostingView.sizingOptions`](https://developer.apple.com/documentation/swiftui/nshostingview/sizingoptions) normally exports SwiftUI's minimum, ideal, and maximum bounds into AppKit. The bridge changes that behavior so width and the width-dependent height can be enforced independently. None of that policy needs to change merely to choose the initial height.

## Why not measure the window in `defaultWindowPlacement`

[`defaultWindowPlacement(_:)`](https://developer.apple.com/documentation/swiftui/scene/defaultwindowplacement(_:)) is a valid SwiftUI-only hook for new windows, and Apple explicitly says restoration uses the saved size and position rather than this default. Its [`WindowLayoutRoot.sizeThatFits(_:)`](https://developer.apple.com/documentation/swiftui/windowlayoutroot/sizethatfits(_:)) proxy asks the content what size it chooses for a proposal.

It is still the weaker first choice for this app. It would introduce a second calculation of “minimum height” in the scene while `.windowMinimumSize` remains the authority for the user's actual resize limit. An unspecified height asks a view for its ideal height, not necessarily its minimum; Apple documents `nil` as an ideal-height proposal in [`ProposedViewSize.height`](https://developer.apple.com/documentation/swiftui/proposedviewsize/height). Asking with a zero height is closer to a minimum query, but this app's state-driven pager measurement makes the result dependent on how the offscreen window root performs its first layout. That is the coupling the rejected refactor exposed.

Use `defaultWindowPlacement` only if the undersized `defaultSize` produces a visible initial correction. In that fallback, keep all content sizing unchanged and return the smallest supported placement; let the existing bridge remain the final authority. Do not add package-page-specific measurement to make scene placement agree with the bridge.

## Why the UserDefaults frame-key approach should stay rejected

AppKit publicly exposes a window's [`frameAutosaveName`](https://developer.apple.com/documentation/appkit/nswindow/frameautosavename-swift.property) and methods such as [`setFrameUsingName(_:)`](https://developer.apple.com/documentation/appkit/nswindow/setframeusingname(_:)) and [`removeFrame(usingName:)`](https://developer.apple.com/documentation/appkit/nswindow/removeframe(usingname:)). Those APIs document that AppKit stores frame data in the defaults system, but they do not document the concrete defaults key, a `"NSWindow Frame "` prefix, or a supported way to infer whether SwiftUI is currently restoring a particular window by enumerating `UserDefaults`.

The macOS 26.5 SDK's public `NSWindow.h` likewise declares the named frame APIs but no storage-key constant. Constructing `"NSWindow Frame " + frameAutosaveName` therefore depends on private persistence representation. It can break if AppKit or SwiftUI changes its keying, restoration timing, scene identifiers, or storage mechanism.

The approach is unnecessary here because both `defaultSize` and `defaultWindowPlacement` already have documented "new window only; restoration wins" semantics.

## Narrow AppKit fallback

If neither SwiftUI default-sizing route avoids a visible flash, keep any fallback entirely inside `WindowMinimumSize`:

- Add one semantic SwiftUI option at the existing call site, such as `windowMinimumSize(addingHeight:startNewWindowAtMinimum:)`.
- Pass that intent through the existing private `NSViewRepresentable`.
- Let `WindowMinimumSizeAppKitView` perform at most one initial `setContentSize` after it has a valid computed minimum.

The hard part is identifying "new, not restored." There is no public AppKit property that answers that for a SwiftUI `WindowGroup`. Do not manufacture the answer from private defaults keys. Unless a verified lifecycle signal becomes available, prefer the documented SwiftUI default-size contract over this fallback.

## Verification checklist

Verify behavior, not a hard-coded point value:

1. Open a brand-new first window and a second new `WindowGroup` window. For both, the starting content height should equal the bridge's effective user-resizable minimum within normal backing-scale rounding.
2. Drag a window taller, quit, and relaunch with restoration enabled. Its restored size must remain unchanged.
3. Restore a window whose saved size is below a newly increased content minimum. It should grow only to the new minimum; Apple documents that [`NSWindow.contentMinSize`](https://developer.apple.com/documentation/appkit/nswindow/contentminsize) is enforced for user and programmatic resizing.
4. Resize across the one-column/two-column breakpoint and switch pager pages. The dynamic package height, animation, and tallest-page behavior must match the pre-change checkpoint.
5. Exercise a deliberately taller picker in a test fixture. It must still determine the pager and window minimum height.
6. Screen-record cold launch and creation of a second window. Reject the undersized-default technique if a one-frame tiny-window flash is visible.

If all six pass, the production change should be confined to the SwiftUI scene's default height (plus an explanatory name/comment); no production changes belong in the package section, pager, or AppKit bridge.
