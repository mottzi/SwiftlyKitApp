# Developing TripleApp

Keep the `TripleApp` and `Triple` repositories beside each other. A development
checkout can use the local library; a standalone project build checks the pinned
remote library dependency.

```text
workspace/
  TripleApp/
  Triple/
```

## Build and run

Building the app requires Xcode with Swift 6.3 or later and the macOS 26.5 SDK or
later. The app's deployment target is macOS 26.5.

Open **`TripleApp.xcworkspace`** for development. Select the **TripleApp**
scheme and **My Mac**, then use **Product > Run** or **Command-R**.
The workspace builds the local library at `../Triple`, including uncommitted
changes. You do not need to publish library changes or update the project's
remote revision to test them in the app.

The workspace includes the sibling `../Triple` package directly. Editing the
library in the workspace edits its original files. Keep the app and library
checkout folders beside each other.

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

For a standalone Release test run, use `-project TripleApp.xcodeproj` instead of
the workspace and add `-configuration Release ENABLE_TESTABILITY=YES`.
Testability is a command-line override; production Release settings stay as
configured. Use a separate test-host bundle identifier if you are running a
signed app copy at the same time.

Run the release script checks with `python3 script/tests/test_release_validation.py`.
They exercise version/build gates and signed entitlement fixtures without
notarizing or publishing artifacts.

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

## Package configuration and build behavior

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

Configuration evaluates the root manifest to list products without resolving
or inspecting dependencies. Build starts cancellable dependency validation,
SDK recovery, and compilation. Resolution can access the network and update
`Package.resolved`. SwiftPM evaluates manifests and can run plugins with the
user's permissions.

The app verifies that the result is a statically linked Linux executable for the
selected architecture. It validates required resource bundles, then exports the
result to an existing empty directory without rebuilding. Stripping creates and
verifies a separate executable copy. It does not modify the unstripped product.

Build Output shows progress, commands, and process output. Its toolbar can wrap
lines, copy the transcript, or clear it. Error details remain available after a
failed build.

## App identity and distribution

The app bundle and executable are `Triple.app` and `Triple`. The Xcode target,
Swift module, test target, and shared scheme use `TripleApp` or `TripleAppTests`.
The main and Help windows display Triple.

The bundle identifier is `codes.mottzi.TripleApp`. This starts a new preferences
domain; preferences from the old app are not migrated automatically. The
Sparkle public signing key remains unchanged, and its Keychain account is
`codes.mottzi.TripleApp`. Release commands use the notarization credential profile
`TripleApp`; save that profile in Keychain before notarizing. The update feed points to the
renamed [`mottzi/TripleApp` repository](https://github.com/mottzi/TripleApp).
[Triple 0.2.0](https://github.com/mottzi/TripleApp/releases/tag/0.2.0) is public
with a signed, notarized DMG and Sparkle appcast.
[The release guide](../Docs/direct-release.md) covers archive export, notarization,
and Sparkle asset preparation.

The [earlier UI audit](../Docs/ui-ux-audit-2026-09-12.md) and screenshots under
`../Docs/` describe the pre-rebrand app. Their historical labels and source paths
remain unchanged. Local release logs and icon research under `../Docs/` also
retain their historical names.
