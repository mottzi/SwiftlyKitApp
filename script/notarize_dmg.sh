#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 /path/to/Triple.app /path/to/output.dmg keychain-profile" >&2
  echo "The app must already be exported with Developer ID Application signing." >&2
  exit 2
}

[[ $# -eq 3 ]] || usage
source_app="$1"
output_dmg="$2"
profile="$3"

[[ -d "$source_app" && "$source_app" == *.app ]] || usage
[[ "$output_dmg" == *.dmg ]] || usage
[[ ! -e "$output_dmg" ]] || { echo "Output already exists: $output_dmg" >&2; exit 1; }

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$source_app/Contents/Info.plist")"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$source_app/Contents/Info.plist")"
[[ "$bundle_id" == "codes.mottzi.SwiftlyKitApp" ]] || { echo "Unexpected bundle ID: $bundle_id" >&2; exit 1; }

signature="$(/usr/bin/codesign -dv --verbose=4 "$source_app" 2>&1)"
identity="$(printf '%s\n' "$signature" | sed -n 's/^Authority=\(Developer ID Application:.*\)$/\1/p' | head -n 1)"
[[ -n "$identity" ]] || { echo "The app is not signed with Developer ID Application." >&2; exit 1; }
printf '%s\n' "$signature" | grep -q '^TeamIdentifier=4DXABR577J$' || { echo "The app is signed by the wrong developer team." >&2; exit 1; }
printf '%s\n' "$signature" | grep -q 'flags=.*runtime' || { echo "The app lacks Hardened Runtime." >&2; exit 1; }
/usr/bin/codesign --verify --deep --strict --verbose=2 "$source_app"
security find-identity -p codesigning -v | grep -Fq "\"$identity\"" || {
  echo "Install a local Developer ID Application identity to sign the outer DMG: $identity" >&2
  exit 1
}
xcrun notarytool history --keychain-profile "$profile" --output-format plist >/dev/null
scratch="$(mktemp -d "${TMPDIR:-/tmp}/triple-notarize.XXXXXX")"
cleanup() {
  local status=$?
  rm -rf "$scratch"
  if (( status != 0 )); then
    rm -f "$output_dmg"
  fi
}
trap cleanup EXIT
app="$scratch/Triple.app"
/usr/bin/ditto "$source_app" "$app"

submit_and_check() {
  local file="$1" response="$2" status submission_id
  xcrun notarytool submit "$file" --keychain-profile "$profile" --wait --timeout 2h --output-format plist > "$response"
  status="$(/usr/libexec/PlistBuddy -c 'Print :status' "$response")"
  submission_id="$(/usr/libexec/PlistBuddy -c 'Print :id' "$response")"
  echo "Notary submission $submission_id: $status"
  if [[ "$status" != Accepted ]]; then
    xcrun notarytool log "$submission_id" --keychain-profile "$profile" >&2 || true
    return 1
  fi
}

zip="$scratch/Triple.zip"
if ! xcrun stapler validate "$app" >/dev/null 2>&1; then
  /usr/bin/ditto -c -k --keepParent "$app" "$zip"
  submit_and_check "$zip" "$scratch/app-notary.plist"
  xcrun stapler staple "$app"
fi
xcrun stapler validate "$app"

stage="$scratch/dmg-content"
mkdir "$stage"
/usr/bin/ditto "$app" "$stage/Triple.app"
ln -s /Applications "$stage/Applications"
mkdir -p "$(dirname "$output_dmg")"
/usr/sbin/diskutil image create from --format UDZO --volumeName "Triple $version" "$stage" "$output_dmg"
/usr/bin/codesign --sign "$identity" --timestamp --identifier "$bundle_id.dmg" "$output_dmg"
/usr/bin/codesign --verify --strict --verbose=2 "$output_dmg"
submit_and_check "$output_dmg" "$scratch/dmg-notary.plist"
xcrun stapler staple "$output_dmg"
xcrun stapler validate "$output_dmg"
/usr/sbin/spctl --assess --type open --context context:primary-signature --verbose=2 "$output_dmg"
/usr/bin/shasum -a 256 "$output_dmg"
echo "Ready for private installation testing: $output_dmg"
