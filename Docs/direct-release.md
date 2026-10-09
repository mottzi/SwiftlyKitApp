# Direct release of SwiftlyKitApp

This is the manual release path for v0.1.0. It keeps App Sandbox off so the app can use local Swift projects and developer tools. It produces a Developer ID signed, hardened, notarized app in a notarized DMG. A private rehearsal is still a real submission to Apple's notary service; it is not a public release.

## One-time setup

1. In Xcode, sign in to the paid Apple Developer team `4DXABR577J`. The private export script and plist select this team. The SwiftlyKitApp target uses version `0.1.0`, Hardened Runtime, Developer Tools category, and no App Sandbox.
2. Install a local **Developer ID Application** identity for this team, including its private key. Xcode's managed cloud signing can export the app, but the local identity is needed to sign the outer DMG. In **Xcode > Settings > Accounts**, select the Apple Account and team, click **Manage Certificates**, then use **+ > Developer ID Application**. An Account Holder can create it. Confirm that `security find-identity -p codesigning -v` lists `Developer ID Application: Berken Sayilir (4DXABR577J)`.
3. Set up `notarytool` credentials in the login keychain. For an Apple ID, first create an app-specific password in your Apple account, then run the command below and enter that password at its secure prompt. An App Store Connect API key is another option. Keep credentials out of the repository.

   ```sh
   xcrun notarytool store-credentials SwiftlyKitApp \
     --apple-id 'YOUR_APPLE_ID' --team-id 4DXABR577J
   ```

## Archive and export

1. Check that the intended source is committed and the target's Marketing Version is `0.1.0`. Increment its Build number for a later build of the same version.
2. Run the app and its tests. Confirm selection, environment preparation, a real package build, and export.
3. Export a Developer ID app into a new private directory. The script makes a hardened ad hoc archive, then has Xcode export it using Developer ID cloud signing. It verifies the final signature.

   ```sh
   release_dir='/absolute/path/to/new/private/SwiftlyKitApp-0.1.0-build'
   script/export_developer_id_app.sh "$release_dir"
   ```

   Xcode Organizer's **Product > Archive > Distribute App > Direct Distribution** is an alternative if your local signing key is available. Inspect the exported app's signature and Hardened Runtime before packaging.
4. Package and notarize the exported app and DMG:

   ```sh
   release_dir='/absolute/path/to/new/private/SwiftlyKitApp-0.1.0-build'
   script/notarize_dmg.sh \
     "$release_dir/Export/SwiftlyKitApp.app" \
     '/absolute/path/to/new/private/SwiftlyKitApp-0.1.0.dmg' \
     SwiftlyKitApp
   ```

   The script checks the app's Developer ID signature and Hardened Runtime, staples the app, makes a DMG with an Applications shortcut, submits the DMG, staples it, checks Gatekeeper, and prints its SHA-256 hash. If Xcode already stapled the app, the script skips its app submission. It refuses to overwrite an existing DMG.

## Private installation test

Open the DMG from the same path a recipient would download, drag the app to Applications, and launch that copy. On a separate Mac or clean macOS account, check that Gatekeeper identifies the developer without the unnotarized-app override, then build and export a trusted sample package. Check both online and offline launch if possible. Keep the private test DMG out of public GitHub releases and the website.

The release build must be archived, signed, and notarized again after any change to its code, assets, version, or build number. The test DMG is evidence that the workflow works; it is not the final v0.1.0 artifact. Record the final DMG's SHA-256 hash alongside the download when publishing.

## Alpha readiness on 2026-10-04

All four product worktrees were clean at the start of this check. The app has
three unpushed commits, including the final Icon Composer asset. Keep the
release guide and release scripts local, as previously agreed.

The library needed a fix before shipping. Swift 6.4 defaults to the Swift Build
engine, whose resource bundle names and metadata layout differ from the native
engine that SwiftlyKit inspects. Local commit `9c65389` selects the native engine
explicitly and extends resource validation to `.bundle` directories. Swift 6.4
still supports the native engine but marks it deprecated. Supporting the default
engine is follow-up work. The fix also corrects a temporary-path test comparison.

The Release library suite passed all 304 tests with acceptance enabled. Real
ARM64 and x86-64 Linux builds and resource export passed with Swift 6.3.3
and 6.4.0. App tests passed all 62 tests, and the current Release app builds with
the icon, version 0.1.0, build 1, and macOS 26.5 minimum. These local verification
bundles use ad hoc signing and are not distributable artifacts.

The normal app also completed an interactive Swift 6.4 x86-64 Linux release
build and exported the executable and required resource bundle into an empty
folder. The exported executable is static ELF, and the resource's contents were
verified. All app checks ran on macOS 27.0.1, so the advertised macOS 26.5 minimum
still needs installation testing on that OS version.

CLI commit `49c68f0` handles newer library preparation components. All 15 CLI
tests passed against both the pinned 0.3.1 dependency and the fixed local library.
Local commits `c1f8e22` in the library, `82f2392` in the app, `6d7baec` in the
CLI, and `c5dca22` in marketing implement the subsequent API rename. It replaces `.publish` with `.export` throughout the
library, app, CLI, and marketing examples, without compatibility aliases. The
CLI dependency is prepared for SwiftlyKit 0.5.0. All 304 library tests, including
real cross-compilation acceptance, all 15 CLI tests against the local library,
and the app test suite passed after the rename. The Release app build passed.
The current CLI lockfile records local-mode dependencies and has no SwiftlyKit
remote pin. Publish library 0.5.0 first, then regenerate the normal CLI lockfile,
verify the remote dependency build, and choose the CLI release version.
Do not deploy marketing examples requiring 0.5.0 before that tag exists.

The complete marketing site remains local. The live site still serves a Hello
World placeholder. Local JavaScript syntax, assets, IDs, and anchors passed
checks. At launch, replace the development label and no-download copy with the
alpha download, retain the Apple silicon and macOS 26.5 requirements, and add
installation steps, release notes, and a feedback link. Deploy the page and its
assets together only after the final DMG has passed installation testing.

Remaining release gates are a fresh Developer ID archive and export, notarization
and stapling of the final app and DMG, strict signature and Gatekeeper checks,
and installation from a browser download on a clean Mac or account. Inspect the
exported app's entitlements and confirm that `get-task-allow` is absent or false.
The previous private rehearsal cannot stand in for these checks after the new
icon and library changes. No push, deployment, release, or notary submission was
performed during this readiness check.

## Private rehearsal on 2026-09-26

The Release build and test suite passed. The `AppIcon` asset compiled with all ten macOS slots. An ad hoc hardened archive exported through Xcode cloud signing produced a valid Developer ID app for team `4DXABR577J`. Xcode uploaded that app to Apple's notary service, and the exported app has a stapled ticket. `codesign --verify --deep --strict`, `stapler validate`, and `spctl --assess --type execute` passed.

A local `Developer ID Application: Berken Sayilir (4DXABR577J)` identity was created in Xcode, and the `SwiftlyKitApp` `notarytool` profile was saved in Keychain. The private DMG at `.derivedData/release-test/SwiftlyKitApp-0.1.0-PRIVATE-TEST-SIGNED-NOTARIZED.dmg` was signed, submitted to Apple's notary service, accepted (submission `010a2876-4391-40f7-8033-24814dd2e05f`), and stapled. `codesign --verify --strict`, `stapler validate`, and `spctl --assess --type open` passed on the DMG. The mounted image contains `SwiftlyKitApp.app` and an Applications shortcut; the embedded app passed strict signature verification, stapler validation, and Gatekeeper assessment.

SHA-256 of this private rehearsal DMG: `1442a61992761cd128e6963d5bd60ad4ecbf4cd97ba677901661f160baa30a84`. It has not been published or tested on a separate clean Mac. Build and notarize the final v0.1.0 artifact again after the remaining app and icon decisions. The earlier unsigned test DMG remains under `.derivedData/release-test/` only for comparison and must not be distributed.

Apple's guides: [Developer ID certificates](https://developer.apple.com/help/account/certificates/create-developer-id-certificates), [Direct Distribution in Xcode](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases), [packaging a Mac app](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution), and [custom notarization](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow).

## Public library release on 2026-10-04

SwiftlyKit 0.5.0 is public at
https://github.com/mottzi/SwiftlyKit/releases/tag/0.5.0, from commit
`e181c50347839528919dfae1e111cecde56c9466`. Older GitHub release entries
0.3.2, 0.4.0, and 0.4.1 were removed after publication. Their Git tags remain.
Release metadata was saved to `/tmp/swiftlykit-release-backup-20261004/releases.json`.

The CLI now uses `from: "0.5.0"` and has no local-library override. The app
uses the equivalent Xcode Up to Next Major Version requirement starting at
0.5.0. Both lockfiles resolve the public release revision. The CLI remote
Release test suite passed all 15 tests, and the app remote Release build passed.
The app tests also passed with the committed dependency lockfile. The CLI
and app dependency updates remain local, with no consumer release,
app notarization, or website deployment performed. The marketing release
notes link now points to 0.5.0 in the local preview.

## Export destination policies prepared for 0.5.1

The next library version is 0.5.1, as requested. The published 0.5.0 release
and its tag remain unchanged. `BuildResult.export(to:policy:)` and
`BuildOutput.export(to:policy:cleanup:)` share `ExportDestinationPolicy`.
Default export uses `.createNewDirectory`; the CLI replacement flag maps to
`.replaceIfPresent`, and the app's folder picker uses
`.requireExistingEmptyDirectory`. The old Boolean and `into:` overload were
removed without aliases. All 308 library tests including real cross-compilation,
all 15 CLI tests, app tests, and the Release app build passed.

CLI and app verification used disposable copies with local dependencies. The
committed projects retain remote ranges starting at 0.5.1. Their lockfiles still
identify the previous public 0.5.0 release and must be regenerated after 0.5.1
is published. No source was pushed, no new library release was published, and
no app notarization, consumer release, or website deployment was performed.
Draft release notes are `/tmp/swiftlykit-0.5.1-release-notes.md`.

## Public 0.5.1 release verified on 2026-10-04

SwiftlyKit 0.5.1 is published from
`d1c0e71663d32e9b2fa9d526bd13ee386271a484`. The app and CLI remote dependency
requirements start at 0.5.1, and both regenerated lockfiles resolve that exact
release revision. App tests, the Release app build, and all 15 CLI tests passed
against the published remote tag without local overrides. Source updates and
READMEs are pushed in the library, CLI, and app repositories. The marketing
README and release-notes link point to 0.5.1, with local verification of assets,
IDs, references, and the release link. The marketing changes are committed
locally; that repository has no Git remote and the site was not deployed.
No app archive, notarization, DMG, or app binary release was produced.

## CLI 0.2.0 released on 2026-10-04

SwiftlyKitCLI 0.2.0 is public at
https://github.com/mottzi/SwiftlyKitCLI/releases/tag/0.2.0. Its source tag
identifies commit `4733ca9`, and it uses the public SwiftlyKit 0.5.1 dependency.
All 15 CLI tests passed in Release configuration, and the built executable
reports `SwiftlyKitCLI 0.2.0`. Build help includes output, replacement, and
cleanup flags. This is a source release installed with `./install.sh`; no
prebuilt binary was uploaded and no user installation was changed.

## Version 0.1.0 release artifact, 2026-10-04

Built version `0.1.0`, build `1`, from clean app `main` commit `d529d34b6b4f54d6533cc5c89e6dd5cb3a6a7198` with remote SwiftlyKit `0.5.1`. The Developer ID archive and export succeeded. Both the app and DMG were accepted by Apple, stapled, and passed strict signature and Gatekeeper checks. The mounted DMG contains the app and an Applications shortcut. The embedded app also passed signature, ticket, version, and Gatekeeper checks.

Final local DMG: `/Users/berken/Library/Mobile Documents/com~apple~CloudDocs/Downloads/SwiftlyKitApp-0.1.0/SwiftlyKitApp-0.1.0.dmg`

SHA-256: `d84e4cd4995d6be804d56eb89bd2f757d84d3fa2625cd8beab4a2adfee45d593`

App notarization submission: `d6af6f4c-0b90-4c83-977f-ca62fc894023`. DMG notarization submission: `9181af10-dd06-455a-9a70-fcd48fad72d3`. Archive, exported app, Apple logs, and verification logs are under `/Users/berken/Development/Swift/SwiftlyKitApp/.derivedData/release-0.1.0-20261004-1119`.

The app binary contains ARM64 and x86_64 slices. Intel runtime behavior has not been tested. The macOS minimum remains `26.5`. A clean-machine installation test remains before publication. This artifact is prepared for a regular `0.1.0` release, without a prerelease suffix. No GitHub release, tag, or website deployment was performed during packaging.

## Published version 0.1.0, 2026-10-04

At the user's request, skipped the additional installation test and proceeded with publication. Published the regular latest GitHub release at https://github.com/mottzi/SwiftlyKitApp/releases/tag/0.1.0 with the signed, notarized DMG and SHA256SUMS.txt. The tag points to the archive source commit `d529d34b6b4f54d6533cc5c89e6dd5cb3a6a7198`. GitHub confirms draft and prerelease are false. Its DMG digest matches the local artifact. The app README download update is committed and pushed as `96f54f7`. Deployed the full marketing page, assets, and data to https://swiftlykit.mottzi.codes with direct app download and release notes links. Verified the live files match local content and the DMG download responds successfully. No new test suite or installation test was run during publication.


## Sparkle update workflow

The app now includes Sparkle 2.10.0. Its feed URL is
`https://github.com/mottzi/SwiftlyKitApp/releases/latest/download/appcast.xml`.
Every stable release must include a DMG and `appcast.xml`. Keep the repository
public. The latest release controls which feed every installed app sees.
Attach all assets to a draft before publishing it as the latest stable release.
Do not publish a newer release without its feed.

Automatic checks default to enabled, on Sparkle's daily schedule. Automatic
installation defaults to disabled. Users can change both preferences in
Settings, choose Install Later or Skip in Sparkle's dialog, and check manually
from the app menu. Update relaunch and normal termination wait for active work
in every build window. Package selections, configuration, results, and logs
are not restored after restart. External projects, outputs, SDKs, and toolchains
are not removed by app updates.

The signing key is stored in the login Keychain under Sparkle's account
`codes.mottzi.SwiftlyKitApp`. `Config/Info.plist` contains only its public key.
Keep the private key available on the Mac that prepares releases and include
the login Keychain in your backups. Do not regenerate the key for each release.
The local preparation script refuses to use a key that differs from the app's
public key. It uses Sparkle's tools from the resolved package artifact. Set
`SPARKLE_TOOLS` to another Sparkle `bin` directory if necessary.

For each release:

1. Increase the target's Marketing Version and Build number. Build numbers must
   increase globally, even across different marketing versions. The current
   public app is 0.1.1, build 2; the next release must exceed both values.
2. Run the tests, archive/export, and notarize with the existing local scripts.
   Never use Debug entitlements for a distributable release. Debug disables
   library validation only so ad hoc builds can load Sparkle during development.
3. Write Markdown release notes and prepare the GitHub assets into a new folder:

   ```sh
   script/prepare_update.sh \
     '/absolute/path/to/SwiftlyKitApp-NEW_VERSION.dmg' \
     '/absolute/path/to/release-notes.md' \
     '/absolute/path/to/new-update-assets'
   ```

   The script verifies the notarized DMG and embedded app, Developer ID team,
   public key, feed URL, version, and increasing build number. It reads the
   latest GitHub release and downloads its previous feed if present. Only
   published 0.1.1 is accepted as the bootstrap release without a feed. For
   recovery or an offline feed copy, supply `previous-appcast.xml` as a fourth
   argument. GitHub metadata is still checked to prevent version reuse.

   Sparkle generates the new signed archive entry with embedded release notes,
   a version-specific GitHub download, and the app's minimum macOS requirement.
   Existing feed entries and their download metadata are retained. Delta updates
   are disabled. The script checks the signature and writes `SHA256SUMS.txt`.
   It does not upload assets, create a tag, or publish a release.
4. Test an upgrade from a genuine previous Sparkle-enabled app to the new signed,
   notarized app. Test Install Later, Skip, disabled automatic checks, automatic
   installation, restart deferral during discovery, tool installation, building,
   exporting and cleanup, including a second window. Test a skipped-version
   upgrade and rejection of an incompatible macOS update. Keep a failed release
   out of the public feed.
5. Create a draft GitHub release tagged at the tested source commit. Attach the
   prepared DMG, `appcast.xml`, and `SHA256SUMS.txt`, and use `release-notes.md`
   for its description. Publish it as a stable latest release after all assets
   are present. Verify the stable feed URL downloads that release's feed.
6. Keep older release assets available. Do not delete compatible feed entries.
   If a published update has a runtime defect, prepare a corrected release with
   a higher build number. If withdrawal is needed, restore the last good feed
   for users who have not updated; already updated users still need a new fix.

Users of 0.1.1 and earlier must manually download and replace the app once.
Explain this in the first Sparkle release's notes and on its download page.
Subsequent versions update through Sparkle. The first public feed may advertise
its own release; future releases add the newer builds to that feed.

### Local implementation checks

Build, launch, preference UI, task lifetime tests, Release dependency resolution,
and feed-generation checks are local verification. They do not replace the
signed/notarized upgrade rehearsal in step 4. No new public release or appcast
has been published by this implementation task. Release scripts and this guide
remain local, as previously agreed.

### Implementation verification, 2026-10-09

The Debug build and launch succeeded through `script/build_and_run.sh --verify`.
The update menu and Settings window were inspected. Automatic checks were on,
automatic installation was off, and its toggle changed and returned to off.
The full app test suite passed in the development workspace, including restart
blocking across windows and cancellation that waits for actual task completion.
The workspace Release build also passed. A local two-DMG fixture passed archive
signature verification and retained the old compatible feed entry without its
old archive being present. Release-script validation accepted the generated
feed and rejected altered history and reused build numbers. The fixtures were
ad hoc signed, not notarized or published; a production upgrade rehearsal is
still required before the first public Sparkle release.

The standalone project build failed against the pinned public SwiftlyKit 0.6.0.
The existing app code requires newer APIs, including `PackageConfiguration`,
`configurePackage`, and the build dependency-resolution argument. These APIs
are available in the local SwiftlyKit workspace. This mismatch predates the
updater changes. Before the existing project-based release export can work,
publish a SwiftlyKit version containing those APIs and update the app's package
requirement and lockfile. This task did not publish or change the library.
