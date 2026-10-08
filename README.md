# SwiftlyKitApp

SwiftlyKitApp is a macOS app that cross-compiles local Swift packages into
verified, statically linked ARM64 or x86-64 Linux Musl executables. Choose a
package, configure its build, and export the executable with its required
resource bundles.

The app uses the [SwiftlyKit](https://github.com/mottzi/SwiftlyKit) Swift library
to manage toolchains, SDKs, and builds. For a terminal command, use
[SwiftlyKitCLI](https://github.com/mottzi/SwiftlyKitCLI).

## Download

[Download SwiftlyKitApp 0.1.1](https://github.com/mottzi/SwiftlyKitApp/releases/download/0.1.1/SwiftlyKitApp-0.1.1.dmg).
Open the DMG, drag SwiftlyKitApp to Applications, and launch it from there.
The app is signed with Developer ID and notarized by Apple.

[Release notes and SHA-256 checksum](https://github.com/mottzi/SwiftlyKitApp/releases/tag/0.1.1)
are available on GitHub.

## Requirements

- Apple silicon Mac running macOS 26.5 or later
- Xcode with Swift 6.3 or later and the macOS 26.5 SDK or later to build the app
- A trusted local Swift package with an executable product and dependencies that
  support Linux Musl

Cross-compilation also needs Swiftly, an official Swift toolchain, and its
matching Static Linux SDK. The app asks before installing missing components
and tells you when preparation may update Swiftly. Downloads and uncached
package dependencies require network access.

## Quick start

1. Click **Select Package** and choose the folder containing `Package.swift`, or
   the manifest itself. You can also drag either into the app.
2. Review any request to install the required Swift tools. Once preparation
   finishes, the app lists the package's executable products.
3. Choose the product, Linux target architecture, build configuration, and Swift
   version. Changing the target or Swift version refreshes product discovery and
   may require another installation.
4. Click **Build** or press **Command-B**. Follow progress in **Build Output**.
5. After a successful build, open **Build files**, choose **Export Build...**,
   and select or create an empty destination folder.

Configuration evaluates the root manifest to list products without resolving
or inspecting dependencies. Clicking Build starts cancellable dependency
validation, SDK recovery, and then compilation. Resolution can access the network
and update `Package.resolved`.
SwiftPM evaluates package manifests and may run plugins with your permissions.
Build only packages you trust.

## Configuration

| Option | Default | Effect |
| --- | --- | --- |
| Product | First discovered executable | Selects the executable product to build. |
| Target | x86_64 Linux | Selects x86-64 or ARM64 Linux Musl. |
| Configuration | Release | Selects an optimized release build or a debug build. |
| Swift | Automatic | Selects a compatible official Swift release and matching SDK, or an exact version you choose. |
| Strip Binary | Off | Removes symbols from a copy of the executable, then verifies it again. |

Automatic selection first uses a compatible official stable version from the
nearest `.swift-version` file. Otherwise, it prefers the newest compatible
installed toolchain and SDK pair, then the newest compatible official stable
release. Compatibility depends on the package's Swift tools requirement and
target architecture. It does not guarantee that the package will compile.

If host manifest compilation fails, the app tries installed macOS SDKs with the
same Swift version. Automatic selection can then assess a newer Swift release;
an exact version or `.swift-version` pin stays fixed. Any required installation
still needs approval. If dependency inspection cannot succeed, the build stops
before compilation and reports the compiler diagnostic and SDK attempts.

Builds use the package's `.build` directory, default package traits, and
SwiftPM's default build concurrency. Root configuration uses separate stable
scratch storage in the user cache directory, so it can run while a build owns
the package's build storage.

## Build output and export

**Build Output** shows progress, commands, and process output. Its toolbar lets
you wrap lines, copy the transcript, or clear it. You can cancel an active build
or open error details when a build fails.

SwiftlyKit verifies that the result is a static Linux executable for the selected
architecture and validates its required resource bundles. **Build files** lists
those files and the settings used for that build. **Show in Finder** reveals
them in build storage.

**Export Build...** copies the verified executable and resource bundles into an
empty folder without rebuilding. Keep the exported files together on Linux.
Static linking does not embed resource bundles. The executable runs on the
selected Linux architecture.

## Build storage

Open the **Package actions** menu beside the package name to manage its build
storage:

| Action | Effect |
| --- | --- |
| Clean Build Artifacts... | Removes compiled products and intermediates while keeping dependency state. |
| Reset Build Storage... | Removes the package's complete SwiftPM build storage, including dependency state. |

Both actions ask for confirmation. Export any build you want to keep before
cleaning or resetting its storage.

## Development

The Xcode project references SwiftlyKit's public repository using Up to Next Major
Version starting at `0.6.0`, equivalent to SwiftPM's `from: "0.6.0"`. The
lockfile records the selected public release. Development uses
`SwiftlyKitApp.xcworkspace`, which overrides that dependency with `../SwiftlyKit`.
The staged configuration interface currently requires the sibling checkout until
the corresponding library release is published. Run the app's test suite from the repository root:

```sh
xcodebuild \
  -workspace SwiftlyKitApp.xcworkspace \
  -scheme SwiftlyKitApp \
  -destination 'platform=macOS' \
  test
```

`script/build_and_run.sh` uses the workspace when the sibling library exists.
It also accepts `--debug` to open LLDB, `--logs` for process logs, and
`--telemetry` for configuration timings from the `PackageDiscovery` category.

For changes spanning the app and library, open `SwiftlyKitApp.xcworkspace`. It
overrides the released SwiftlyKit package with the sibling `../SwiftlyKit` checkout.
The project alone continues to use the released package.

To exercise the real Deployer configuration and build workflow, run:

```sh
./script/verify_deployer.sh /path/to/Vapor-Deployer
```

The script builds the workspace and passes the package path into the test host
through its generated `.xctestrun` configuration. The acceptance test selects
Swift 6.3.3 explicitly, validates dependency inspection, and checks the app's
completed build result. The toolchain and Static Linux SDK must already be installed.

To measure package selection through usable configuration, including the SwiftUI
discovery task and transition completion, run:

```sh
./script/benchmark_deployer_setup.sh /path/to/Vapor-Deployer 2
```

The optional limit applies to every run. The test records first and repeated
selections separately for Automatic and exact Swift 6.3.3. Compilation and
dependency validation are measured by the separate acceptance workflow.
