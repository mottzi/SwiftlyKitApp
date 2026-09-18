# SwiftlyKit UI/UX audit

Reviewed on 12 September 2026.

The app's compact two-panel structure is worth keeping. The strongest improvements make the selected build unambiguous, explain what is blocking progress, and hand the developer a complete Linux deliverable. A new navigation system or larger configuration form would not help these problems.

This is an audit and proposal, with no product source changes. I inspected the running app with computer use, rebuilt the current checkout after finding that the original running binary was older, and used isolated copies of the current source for additional live fixtures. Those copies only seed an initial package; a second copy requests a 300-point initial width. They preserve the production views, discovery and build workflows, and minimum-size implementation. The audit tooling is outside the repository at `/tmp/swiftlykit-ui-audit-20260912/app-harness`.

The computer-use adapter could read and activate accessibility controls, but coordinate dragging failed and valid-folder selection became unreliable. The isolated copies let me inspect downstream states and a genuinely narrow window without changing the real app. I have not classified that adapter behavior as an application defect. Invalid-folder feedback was separately reproduced and confirmed in source.

**Layout contract preserved by these proposals.**

| Existing rule | Constraint on any implementation |
| --- | --- |
| Package panel above build panel | Preserve this hierarchy and the current pager. |
| Default scene size 500 × 420, declared width floor 300 | Add no wider permanent controls or larger window requirement. |
| Package height is intrinsic; extra height goes to the build area | Add no persistent form rows, banners or inline expanded diagnostics. |
| Build area minimum 176 points; status row 48 points | Reuse the status row's existing two lines and action slot. |
| Console minimum 112 points, toolbar 27 points | Keep console controls within the existing toolbar. |
| Window minimum reserves the one-column configuration height even in two-column mode | Preserve the reservation and independent width/height floors. |
| Picker has a 38-point trailing reveal, 10-point gap, and existing transforms | Keep resting geometry. Accessibility and motion changes must leave measurement intact. |

The visible-content minimum is the larger of measured package height and reserved one-column height, plus 202 points. The AppKit bridge also accounts for toolbar space. See [AppView.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/AppView.swift:8), [WindowMinimumSizeModifier.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/WindowMinimumSize/WindowMinimumSizeModifier.swift:47), and [WindowMinimumSizeAppKitView.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/WindowMinimumSize/WindowMinimumSizeAppKitView.swift:96).

The 300-point audit window displayed every configuration control and retained both panels. At 500 points, a long product name correctly triggered the existing one-column arrangement. There is no evidence here that the layout system needs replacement.

**Recommended changes, in priority order.**

1. **Hand off every file needed to run the build.**

   Live observation: after successfully building CrossCompilationFixture, the Finder action selected only the executable. Its sibling `ResourceDependency_ResourceDependency.resources` remained unselected among compiler intermediates. The executable calls a dependency that reads this bundle at runtime. Static linking does not make those resources part of the binary.

   Start with the small fix: reveal the executable and the exact `BuildResult.resourceBundles` together. For the complete workflow, add an “Export Build…” action to a compact result menu or popover. Export a directory containing the executable under its original product name and those required bundles. Obtain the name from the completed build snapshot, not the stripped scratch filename. Keep “Show in Finder” available. When there are no resources, the handoff can remain a single executable.

   A second live check with Strip Binary enabled produced `.CrossCompilationFixture.swiftlykit-stripped`, beside the original unstripped executable. Finder successfully selected it, but this internal dot-prefixed name is a poor deployment handoff. The exported executable should have the normal product name.

   This belongs in the existing result action slot. It requires no larger status strip or new permanent row. Do not copy the whole scratch directory, which includes build intermediates and can contain unrelated products.

   Evidence: [BuildStatus.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/BuildSection/BuildStatus.swift:112), [BuildResult.swift](/Users/berken/Development/Swift/SwiftlyKit/Sources/SwiftlyKit/Build/BuildResult.swift:9), [resource loading](/Users/berken/Development/Swift/SwiftlyKit/Tests/SwiftlyKitTests/Fixtures/CrossCompilationPackage/Dependencies/ResourceDependency/Sources/ResourceDependency/ResourceDependency.swift:4), [existing publication contract](/Users/berken/Development/Swift/SwiftlyKit/Sources/SwiftlyKit/SwiftPM/Output/AtomicOutputPublisher.swift:35).

2. **Keep the executable the user selected.**

   Live reproduction: choose Beta in a package containing Alpha, Beta and Broken. Change Target from x86_64 Linux to ARM64 Linux. Once discovery finishes, Product silently becomes Alpha, although Beta is still available.

   Preserve the selected product name when it exists in the newly discovered list. Choose the first product only when the previous choice is unavailable. Clear this preference when changing packages. This prevents wrong-product builds and removes a repeated correction, with no visual or sizing change.

   Evidence: [ProductDiscovery.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Models/Discovery/ProductDiscovery.swift:216).

3. **Distinguish the last completed build from the current choices.**

   Live reproduction: build for x86_64, then select ARM64. The lower panel continues to say “Build succeeded” and its Finder action still points to the x86_64 executable. This is useful history, but the relationship to the new target is unclear, especially when the path is truncated.

   Retain an immutable snapshot of the choices that produced the result. When current choices differ, use “Last build succeeded” and identify the result's architecture and configuration in the existing subtitle. Keep the old output accessible. The new selection must never make an older artifact look like a completed build for that selection.

   This is a small model change justified by a visible workflow problem. It should not become a general state-management rewrite. Keep the 48-point strip and use a tooltip or result popover for the complete path and build identity.

   Evidence: [BuildOptions.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Models/BuildOptions.swift:20), [BuildSection.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/BuildSection/BuildSection.swift:12), [BuildStatus.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/BuildSection/BuildStatus.swift:149).

4. **Use the existing status row for setup progress and blockers.**

   Live observations: a library-only package, an unavailable Swift tools version and a malformed manifest all leave the lower panel saying “Complete package discovery to enable building.” Discovery has already ended in each case. The useful explanation and recovery action are behind a small Product or Swift accessory. The no-executable state even uses the same information symbol as ordinary help.

   Keep the form accessories, but put the current task or blocker in the lower status row. Examples are “Checking Swift compatibility,” “No executable products,” and “Package inspection failed.” Reuse its existing action slot for the appropriate recovery action or to open the relevant popover. A library-only package primarily needs another package or an executable added to its manifest; repeatedly retrying the unchanged library is not useful.

   Apply the same presentation to actual download/install progress and cleanup. These operations currently have discovery detail or an `isRunning` flag, but the lower status area does not explain them. Installation and cleanup execution were source-reviewed rather than run during this audit.

   This follows Apple's guidance to integrate status feedback into the interface. It also fits the existing two-line status design. [Apple feedback guidance](https://developer.apple.com/design/human-interface-guidelines/feedback)

   Evidence: [idle status](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/BuildSection/BuildStatus.swift:159), [product states](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/PackageSection/Discovery/ProductDiscoveryStatus.swift:10), [toolchain states](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/PackageSection/Discovery/SwiftDiscoveryStatus.swift:44), [cleanup state](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Models/BuildStorageMaintenance.swift:29).

5. **Summarize the actual compiler error, and show its transcript once.**

   Live reproduction: a source file containing `print(missingAuditSymbol)` fails as expected. The status subtitle starts “SwiftPM could not build the executable: Building for production...” and truncates the useful error. The console first shows the compiler output, then repeats it as a red final error block, including ordinary progress lines.

   Derive a short display summary from the first useful source-located compiler error. Here, it should be “Cannot find 'missingAuditSymbol' in scope.” Keep the source location and retained diagnostic available in details. Display one compact final failure line instead of repeating the entire transcript in red. Preserve diagnostic text for copying, including failures from commands whose output was not streamed.

   A small failure presentation type with summary and detail is warranted. Use it in the existing subtitle and details popover. Keep path middle-truncation for paths; ordinary diagnostic prose benefits from tail truncation. No additional inline height is needed.

   Evidence: [BuildWorkflow.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Models/BuildWorkflow/BuildWorkflow.swift:163), [status subtitle](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/BuildSection/BuildStatus.swift:25), [BuildLogEntry.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Models/BuildWorkflow/BuildLogEntry.swift:9), [console rendering](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/BuildSection/BuildConsole.swift:125).

6. **Make package selection recoverable and package replacement direct.**

   Live observation: selecting an empty directory without Package.swift closes the importer and returns to the unchanged picker with no explanation. Source confirms the invalid URL is silently ignored. The normal replacement path is Package actions → Close Package → Select Package → importer.

   Explain an invalid selection with a concise alert such as “No Package.swift found in NotAPackage,” with an option to choose again. Add “Choose Another Package…” to the existing package menu and a conventional Open Package command with Command-O. Keep the previous package if the chooser is cancelled. Replace an open package in place. Retain the existing picker-to-configuration transition when starting from the empty state.

   The model already accepts a dropped Package.swift, while the importer accepts folders only. Supporting either a package folder or its manifest would make the two entry paths consistent. Validate the choice before changing the current session.

   These changes use the current picker, menu and system dialog. They add no persistent chrome. Recent-package management could come later if repeated reopening proves common; it is not necessary for this pass.

   Evidence: [PackageModel.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Models/PackageModel.swift:35), [PackagePickerPage.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/PackageSection/PackagePickerPage/PackagePickerPage.swift:47), [PackageActionsMenu.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/PackageSection/PackageConfigurationPage/PackageActionsMenu.swift:12).

7. **Exclude the inactive page from accessibility and interaction.**

   Live observation: on the empty picker screen, the accessibility tree contains Target, Configuration, Strip Binary, Package actions and the other configuration controls from the offscreen page. Activating the offscreen Target through accessibility opens its menu. After selection, the obsolete Select Package button remains in the tree as a disabled control.

   Keep both pages mounted for measurement and animation, but expose only the selected page to assistive technology, keyboard focus and hit testing. The visible trailing preview can remain exactly as it is.

   Evidence: [PackageSection.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/PackageSection/PackageSection.swift:16), [deemphasis modifier](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/DeemphasisedContentModifier.swift:8), [configuration controls](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/PackageSection/PackageConfigurationPage/PackageConfigurator.swift:52).

8. **Pause console following when the user scrolls away.**

   Source-confirmed behavior: every log revision scrolls to the bottom while Follow Output is enabled. Manual scrolling does not turn following off. The existing button allows a workaround, but a developer inspecting an earlier diagnostic should not have to anticipate the next log update.

   Pause following when the user scrolls away from the bottom. Resume when they return to the bottom or activate the existing Follow button. Retain the visible state of that button. Wrapping should also preserve the reader's position when following is paused.

   This changes behavior within the existing console. I inspected the wrap toggle and scrollable output, but did not reproduce a long-running scroll-versus-new-output race live because the fixture builds completed quickly.

   Evidence: [BuildConsole.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/BuildSection/BuildConsole.swift:104).

9. **Honor Reduce Motion throughout the package section.**

   Source-confirmed inconsistency: build status and discovery spinners consult Reduce Motion, while package opening, closing, adaptive reflow, and picker hover/press movement do not.

   Suppress spatial animation under that preference, retaining the same final frames, panel heights and trailing preview. Keep the normal animation unless a separate interaction test shows a problem. The audit gives no reason to redesign the animation style generally.

   Evidence: [package opening](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/PackageSection/PackagePickerPage/PackagePickerPage.swift:72), [package closing](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/PackageSection/PackageConfigurationPage/PackageActionsMenu.swift:119), [adaptive animation](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/PackageSection/PackageLayoutAnimation.swift:5), [existing status handling](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitApp/Views/BuildSection/BuildStatus.swift:135).

10. **Give Help a useful destination.**

    Live observation: Help → SwiftlyKitApp Help opens “Help isn't available for SwiftlyKitApp.” Link that command to a short guide covering package requirements, server architecture, static executables, resource bundles, and the output location. This removes a dead end without adding anything to the main window.

    The About window also uses the placeholder app icon and development-facing SwiftlyKitApp name. That is release polish, below the build-workflow issues above.

**Small visual refinements worth a separate, limited pass.**

- A valid single executable currently looks unavailable because Product is a disabled menu. Consider a normal-contrast read-only value while retaining the exact reserved control width and accessory position. Recheck long names and both grid arrangements before accepting this change.
- The current circular primary action uses a play glyph, while it only builds a Linux executable. A build glyph could clarify its meaning within the same measured bounds. Its placement, tooltip and Command-B shortcut already work. This is lower priority than the confirmed workflow defects.
- Configuration help currently restates that it chooses a SwiftPM configuration. Explain the practical Release versus Debug choice instead. The Swift popover can state the exact version Automatic currently resolved to. Keep these additions inside existing popovers, not in longer picker labels that change grid breakpoints.
- The console gives long subprocess commands strong accent color, and they occupy much of the compact viewport. Muting routine commands would let compiler diagnostics stand out while retaining all command text. Avoid adding a row of log filters unless actual usage justifies it.

**Coverage and limits.**

| Workflow or view | Review performed |
| --- | --- |
| Empty state and system package importer | Live current app; invalid folder reproduced; folder-only restriction inspected. |
| Package selection and closing | Source inspected; closing and page return exercised live. Drag/hover movement was source-reviewed because coordinate automation failed. |
| Configuration, all five help popovers, target/Swift/configuration menus | Live. Single-product and multi-product cases inspected. |
| Package actions | Live menu, clean/reset confirmations and cancellation. Existing build storage was not deleted. |
| Host readiness, missing Command Line Tools, unsupported Mac | All view branches source-reviewed. No host tools removed or system installation run. |
| Toolchain/product discovery | Live progress, ready, no compatible tools, no executables, malformed-manifest failure, expanded details and Retry. |
| Required component installation | Live approval alert and cancellation. Download, verification, installation and declined-first-setup branches source-reviewed. No additional toolchains installed. |
| Build | Live build progress, ordinary and stripped success, intentional compiler failure, cancellation, and configuration changes. Dependency-resolution and transient phase presentations also inspected in source and Xcode preview. |
| Console | Live wrapped/unwrapped output, diagnostics and available controls. Copy/clear implementation inspected. Long-running follow race source-reviewed. |
| Completed artifact handoff | Live Finder selection and sibling resource bundle checked. Library result and publication contract confirmed. No server deployment performed. |
| Window sizes | Live ordinary widths and a separate 300-point initial-width copy. Continuous resize transitions checked against source and existing tests rather than a successful computer-use drag. |
| App, File, Window, Help and About | Live menus and dialogs. No custom Settings scene exists. |
| Appearance and motion preferences | Dark appearance inspected live; existing Xcode state preview rendered. Reduce Motion behavior source-reviewed. System preferences were not changed. |

For implementation acceptance, retain the existing minimum-size, adaptive-grid and pager tests. In particular, the production AppView test cycles 700 → 300 → 700 → 300 while requiring unchanged height. Also check long package/product names, paths, blocked setup, success with resources and a long compiler error at the narrow width. Source tests are in [WindowMinimumSizeTests.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitAppTests/WindowMinimumSizeTests/WindowMinimumSizeTests.swift:83), [WindowMinimumDynamicWidthTests.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitAppTests/WindowMinimumSizeTests/WindowMinimumDynamicWidthTests.swift:9), and [PagingHStackTests.swift](/Users/berken/Development/Swift/SwiftlyKitApp/SwiftlyKitAppTests/PagingHStackTests.swift:70). They were inspected, not rerun for this report.

I would start with artifact handoff, product preservation, last-build identity, setup feedback and compiler-error presentation. Those improvements directly shorten the route to the intended Linux executable or prevent the wrong output being used. The existing layout can support all of them.
