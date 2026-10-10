# Triple

Triple is a macOS app that cross-compiles local Swift packages into
verified, statically linked ARM64 or x86-64 Linux Musl executables. Choose a
package, configure its build, and export the executable with its required
resource bundles.

The app uses the [Triple](https://github.com/mottzi/Triple) Swift library
to manage toolchains, SDKs, and builds. For a terminal command, use
[TripleCLI](https://github.com/mottzi/TripleCLI).

## Download

The Triple release is pending. The last published app remains
[SwiftlyKitApp 0.1.1](https://github.com/mottzi/SwiftlyKitApp/releases/tag/0.1.1),
with its original release name and DMG asset. A Triple download will be linked
once a signed Triple release is published.

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

Triple verifies that the result is a static Linux executable for the selected
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

Open **`TripleApp.xcworkspace`** for development. Select the **TripleApp**
scheme and **My Mac**, then use **Product > Run** or **Command-R**.
The workspace builds the local library at `../Triple`, including uncommitted
changes. You do not need to publish library changes or update the project's
remote revision to test them in the app.

The workspace includes the sibling `../Triple` package directly. Editing the
library in the workspace edits its original files. Keep the app and library
checkout folders beside each other. See [the local library setup](Development/README.md).

`TripleApp.xcodeproj` keeps the pinned [GitHub library dependency](https://github.com/mottzi/Triple)
for release builds. Open the project by itself to test that dependency. Its
pinned commit must exist on GitHub. The release export script always uses the
project, so it does not include the workspace's local override.

Run the app's test suite from the repository root:

```sh
xcodebuild \
  -workspace TripleApp.xcworkspace \
  -scheme TripleApp \
  -destination 'platform=macOS' \
  test
```

`script/build_and_run.sh` uses the development workspace when the sibling library
exists. It also accepts `--debug` to open LLDB, `--logs` for process logs, and
`--telemetry` for configuration timings from the `PackageDiscovery` category.
`script/xcodebuild.sh` forwards commands to Xcode without rewriting Git URLs.

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

## App identity and updates

The app bundle and executable are `Triple.app` and `Triple`. The Xcode target,
Swift module, test target, and shared scheme use `TripleApp` or `TripleAppTests`.
The main and Help windows display Triple.

The bundle identifier is `codes.mottzi.TripleApp`. This starts a new preferences
domain; preferences from the old app are not migrated automatically. The
Sparkle public signing key remains unchanged, and its Keychain account is
`codes.mottzi.TripleApp`. Release commands use the notarization credential profile
`TripleApp`; save that profile in Keychain before notarizing. The update feed points to the
renamed [`mottzi/TripleApp` repository](https://github.com/mottzi/TripleApp).
The rebranded source is published, but a signed Triple app release and its
appcast are still pending. [The release guide](Docs/direct-release.md) covers
archive export, notarization, and Sparkle asset preparation.

`Docs/ui-ux-audit-2026-09-12.md` and the screenshots under `Docs/` describe the
pre-rebrand app. Their historical labels and source paths remain unchanged.
Local release logs and icon research under `Docs/` also retain their historical names.
