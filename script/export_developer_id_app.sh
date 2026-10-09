#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || -e "$1" ]]; then
  echo "Usage: $0 /path/to/new-private-output-directory" >&2
  echo "The output directory must not already exist." >&2
  exit 2
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output="$1"
mkdir -p "$output"

xcodebuild \
  -project "$root/SwiftlyKitApp.xcodeproj" \
  -scheme SwiftlyKitApp \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$root/.derivedData/release-build" \
  -archivePath "$output/SwiftlyKitApp.xcarchive" \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=4DXABR577J \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$output/SwiftlyKitApp.xcarchive" \
  -exportPath "$output/Export" \
  -exportOptionsPlist "$root/script/DeveloperIDExportOptions.plist" \
  -allowProvisioningUpdates

app="$output/Export/SwiftlyKitApp.app"
signature="$(codesign -dv --verbose=4 "$app" 2>&1)"
printf '%s\n' "$signature" | grep -q '^Authority=Developer ID Application:'
printf '%s\n' "$signature" | grep -q '^TeamIdentifier=4DXABR577J$'
printf '%s\n' "$signature" | grep -q 'flags=.*runtime'
codesign --verify --deep --strict --verbose=2 "$app"
echo "Developer ID app ready for notarization: $app"
