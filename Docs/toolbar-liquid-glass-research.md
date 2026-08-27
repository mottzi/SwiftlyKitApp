# Conditional Liquid Glass toolbar animations on macOS 26

## Bottom line

SwiftUI has no public API that explicitly requests a morph or materialize transition for a native toolbar item. The native toolbar decides the effect. Apple documents morphing for navigation transitions and presentations, but does not promise the same effect for every state-driven insertion or removal.

For this macOS toolbar, the working native implementation is a conditional `ToolbarItem` for Clear followed by a persistent `ToolbarItem` for Run. AppKit automatically puts adjacent actions in shared Liquid Glass. Apply `.animation(_:value:)` to the view that owns `.toolbar`, after the toolbar modifier.

```swift
struct AppToolbar: ToolbarContent {
    @Environment(PackageModel.self) private var packageModel

    var body: some ToolbarContent {
        if packageModel.isPackageSelected {
            ToolbarItem(placement: .primaryAction) {
                ClearPackageButton()
                    .labelStyle(.iconOnly)
            }
        }

        ToolbarItem(placement: .primaryAction) {
            RunButton()
                .labelStyle(.iconOnly)
        }
    }
}

// On the native toolbar host:
content
    .toolbar { AppToolbar() }
    .animation(.default, value: packageModel.isPackageSelected)
```

This keeps the Run item's identity stable while inserting or removing only the Clear item. The native toolbar can then animate its shared background from a single-item capsule to a two-item capsule and back. Replacing a complete `ToolbarItemGroup` makes macOS replace the logical group, which snapped in the verified reproduction instead of morphing.

## What Apple actually documents

- Toolbars get system-provided Liquid Glass and automatic grouping on iOS 26 and macOS 26. Apple recommends standard toolbar APIs and `ToolbarSpacer` for intentional visual separation. [WWDC25: Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/?time=469) and [Landmarks toolbar sample](https://developer.apple.com/documentation/swiftui/landmarks-refining-the-system-provided-glass-effect-in-toolbars)
- Apple says toolbar items can morph during navigation transitions. It does not say that every conditional `ToolbarContent` update morphs. [WWDC25: What's new in SwiftUI](https://developer.apple.com/videos/play/wwdc2025/256/?time=1244)
- `ToolbarItemGroup` is not an `HStack`. Each child view in its content builder becomes its own toolbar item, preserving native layout and spacing. [ToolbarItemGroup initializer](https://developer.apple.com/documentation/swiftui/toolbaritemgroup/init(placement:content:))
- Apple recommends hiding the whole toolbar item rather than hiding the view inside it. On macOS, `ToolbarContent.hidden(_:)` maps cleanly to native item visibility and prevents an empty glass item. Neither its documentation nor `NSToolbarItem.isHidden` promises an animation. [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass) and [`NSToolbarItem.isHidden`](https://developer.apple.com/documentation/appkit/nstoolbaritem/ishidden)
- Apple provides deterministic morph and materialize controls only for custom glass views in a `GlassEffectContainer`. Those APIs are `glassEffectID(_:in:)` and `glassEffectTransition(_:)`. They are `View` modifiers, not `ToolbarContent` modifiers, so they do not control the glass that the system injects behind a native toolbar item. [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views) and [`GlassEffectTransition.materialize`](https://developer.apple.com/documentation/swiftui/glasseffecttransition/materialize)

## Why the obvious variants fail

### One `ToolbarItem` containing an `HStack`

The system sees one toolbar item. It cannot detach one button from the shared native toolbar group because there are no separate native items to detach.

### A `ToolbarItemGroup`, whether persistent or conditionally replaced

Both forms are valid SwiftUI. The linked iOS workaround reports better results when the conditional surrounds two complete `ToolbarItemGroup` values. Testing that exact arrangement on macOS 26.5.2 still produced a one-frame replacement. A group is a logical toolbar configuration; swapping it does not preserve the identity of the persistent Run item in the way required for this macOS resize animation. See [Liquid Glass Animation for resizing a collection of controls](https://stackoverflow.com/questions/79683015/liquid-glass-animation-for-resizing-a-collection-of-controls) and the [idle-time/rapid-switch report](https://stackoverflow.com/questions/79876073/liquid-glass-toolbar-animation-only-plays-when-switching-state-rapidly).

### Independent `ToolbarItem` values

This is the working macOS structure. Clear is conditionally inserted and Run remains present as a stable sibling. Because both use `.primaryAction` with no separating `ToolbarSpacer`, the system groups them on one glass surface. Insertion and removal animate the shared capsule while the Run button stays anchored.

### `ToolbarContent.hidden(_:)`

This is Apple's correct API for hiding an entire native toolbar item on macOS. It is useful for visibility and toolbar customization semantics, not a documented transition API. If it changes instantly, adding another animation modifier does not force AppKit to interpolate `NSToolbarItem.isHidden`.

### `withAnimation` only inside `ClearPackageButton`

That supplies an animated transaction for the model mutation, but the toolbar host still needs to observe the state change within an animated scope. The placement with the strongest evidence is `.animation(.default, value:)` after `.toolbar` on the owning view. Adding `.transition` or `.glassEffectTransition` to the button content does not configure the system-provided toolbar glass.

### IDs and forced identity changes

`ToolbarItem(id:)` IDs support customizable toolbars. Apple does not describe them as matched-transition IDs. Changing `.id(...)` on the toolbar host forces replacement and can destroy the continuity needed for a native morph. Leave the toolbar host stable.

## The idle-time report

The user-linked question is an iOS 26 report, not a macOS example. Its original code attaches different `.toolbar` modifiers to alternate content views. Normal switches update instantly, while rapid switches sometimes overlap long enough to reveal the native animation. Two answers treat this as unintended framework behavior. The accepted answer moves one toolbar to a stable common ancestor, switches between complete `ToolbarItemGroup` values, and applies `.animation` after `.toolbar`.

SwiftlyKit already has one stable toolbar owner. The iOS group-replacement workaround is not the macOS fix. The macOS toolbar needs stable sibling item identity instead.

## Verified macOS result

The variants were built and screen-recorded on macOS 26.5.2 with Xcode 26.6. Each test selected a package, waited five seconds, then cleared it. This specifically exercises the idle path from the linked report.

- One toolbar item containing an `HStack`: snaps.
- One `ToolbarItemGroup` with conditional children: snaps.
- Two alternate complete `ToolbarItemGroup` branches: snaps.
- A conditional Clear `ToolbarItem` plus a persistent Run `ToolbarItem`: animates in both directions. Ten-frame-per-second inspection shows the shared capsule expanding and contracting across several frames, with the Run item remaining anchored.

## macOS limits and checks

- Apple's SwiftUI and Liquid Glass presentations cover macOS 26, but the community repros above target iOS. Native toolbar animation details differ because macOS uses `NSToolbar`.
- The macOS 26.5 SwiftUI interface has `ToolbarContent.hidden(_:)`, `ToolbarItemGroup`, and `sharedBackgroundVisibility(_:)`. It has no toolbar-content transition or toolbar-item morph identifier.
- Reduce Motion can remove or simplify the effect. Apple explicitly says standard Liquid Glass components adapt to Reduce Motion and Reduce Transparency. Check System Settings > Accessibility > Motion before judging the result. [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass) and [`accessibilityReduceMotion`](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion)
- Test after several seconds of idle time, then test both insertion and removal. A rapid toggle is not proof that the normal path works.

## If independent items still fail

At that point the limitation is the native macOS toolbar implementation, not a missing SwiftUI animation modifier. There is no supported API to force its detach transition.

The reliable fallback is a custom trailing control cluster built with `GlassEffectContainer`, separate `.glassEffect()` controls, stable `glassEffectID` values in one namespace, and an explicit `withAnimation`. Use `.glassEffectTransition(.materialize)` for a standalone item or the default matched-geometry transition for nearby controls. That gives deterministic animation, but it is no longer a native `NSToolbar` item cluster and must reproduce toolbar placement, overflow, customization, accessibility, and window behavior.

The practical order is:

1. Use independent, adjacent `ToolbarItem` values and keep persistent actions structurally stable.
2. Apply `.animation(_:value:)` immediately after `.toolbar` on the stable owner.
3. Confirm Reduce Motion is off and verify after idle time.
4. If a different toolbar arrangement still snaps, file a minimal Feedback Assistant report or use a custom glass cluster with explicit transitions.
