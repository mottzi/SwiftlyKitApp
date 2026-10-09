#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 notarized.dmg release-notes.md new-output-directory [previous-appcast.xml]" >&2
  exit 2
}

[[ $# -eq 3 || $# -eq 4 ]] || usage
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dmg="$1"
notes="$2"
output="$3"
[[ -f "$dmg" && "$dmg" == *.dmg && -s "$notes" && "$notes" == *.md ]] || usage
[[ ! -e "$output" ]] || { echo "Output already exists: $output" >&2; exit 1; }
[[ $# -lt 4 || -f "$4" ]] || usage
repo="mottzi/TripleApp"
account="codes.mottzi.SwiftlyKitApp"

tools="${SPARKLE_TOOLS:-}"
if [[ -z "$tools" ]]; then
  for data in "$root/.derivedData/release-build" "$root/.derivedData"; do
    candidate="$data/SourcePackages/artifacts/sparkle/Sparkle/bin"
    if [[ -x "$candidate/generate_appcast" ]]; then
      tools="$candidate"
      break
    fi
  done
fi
[[ -x "$tools/generate_appcast" && -x "$tools/sign_update" && -x "$tools/generate_keys" ]] || {
  echo "Resolve the Sparkle dependency first, or set SPARKLE_TOOLS to its bin directory." >&2
  exit 1
}
expected_key="$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$root/Config/Info.plist")"
[[ "$("$tools/generate_keys" --account "$account" -p)" == "$expected_key" ]] || {
  echo "The Keychain signing key does not match the app's public key." >&2
  exit 1
}

scratch="$(mktemp -d "${TMPDIR:-/tmp}/triple-update.XXXXXX")"
mounted=false
cleanup() {
  if [[ "$mounted" == true ]]; then
    if ! /usr/sbin/diskutil eject "$scratch/mount" >/dev/null; then
      echo "Could not eject the verification image. Temporary files remain at $scratch." >&2
      return
    fi
  fi
  rm -rf "$scratch"
}
trap cleanup EXIT
mkdir "$scratch/mount" "$scratch/assets"
stage="$scratch/assets"

/usr/bin/codesign --verify --strict "$dmg"
xcrun stapler validate "$dmg"
/usr/sbin/spctl --assess --type open --context context:primary-signature "$dmg"
/usr/sbin/diskutil image attach --readOnly --nobrowse --mountPoint "$scratch/mount" "$dmg" >/dev/null
mounted=true
app="$scratch/mount/Triple.app"
plist="$app/Contents/Info.plist"
/usr/bin/codesign --verify --deep --strict "$app"
xcrun stapler validate "$app"
signature="$(/usr/bin/codesign -dv --verbose=4 "$app" 2>&1)"
printf '%s\n' "$signature" | /usr/bin/grep -q '^Authority=Developer ID Application:'
printf '%s\n' "$signature" | /usr/bin/grep -q '^TeamIdentifier=4DXABR577J$'
printf '%s\n' "$signature" | /usr/bin/grep -q 'flags=.*runtime'
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist")" == "$account" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$plist")" == "$expected_key" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :SUFeedURL' "$plist")" == "https://github.com/$repo/releases/latest/download/appcast.xml" ]]
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")"
build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist")"
[[ "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ && "$build" =~ ^[1-9][0-9]*$ ]] || {
  echo "Use a stable numeric marketing version and a positive integer build number." >&2
  exit 1
}
/usr/sbin/diskutil eject "$scratch/mount" >/dev/null
mounted=false

# fetch a known release so a concurrent publication cannot mix its metadata and feed
gh release view --repo "$repo" --json tagName,assets > "$scratch/latest.json"
python3 - "$scratch/latest.json" "$version" <<'PY'
import json, re, sys
latest = json.load(open(sys.argv[1]))['tagName'].removeprefix('v')
def parts(value):
    if not re.fullmatch(r'\d+\.\d+(?:\.\d+)?', value):
        raise SystemExit('The latest stable release does not have a numeric version.')
    result = tuple(map(int, value.split('.')))
    return result + (0,) * (3 - len(result))
if parts(sys.argv[2]) <= parts(latest):
    raise SystemExit('Increment the marketing version above the latest public release before preparing an update.')
PY
if [[ $# -eq 4 ]]; then
  cp "$4" "$stage/appcast.xml"
else
  latest_tag="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["tagName"])' "$scratch/latest.json")"
  if python3 -c 'import json,sys; sys.exit(not any(a["name"] == "appcast.xml" for a in json.load(open(sys.argv[1]))["assets"]))' "$scratch/latest.json"; then
    gh release download "$latest_tag" --repo "$repo" --pattern appcast.xml --dir "$stage"
  elif [[ "$latest_tag" == "0.1.1" ]]; then
    echo "No feed exists in the latest release. Preparing the first Sparkle release."
  else
    echo "The latest release is missing appcast.xml. Supply the previous feed explicitly to preserve update history." >&2
    exit 1
  fi
fi
if [[ -f "$stage/appcast.xml" ]]; then
  cp "$stage/appcast.xml" "$scratch/previous.xml"
  python3 - "$stage/appcast.xml" "$build" <<'PY'
import sys, xml.etree.ElementTree as ET
ns = '{http://www.andymatuschak.org/xml-namespaces/sparkle}'
for item in ET.parse(sys.argv[1]).findall('./channel/item'):
    enclosure = item.find('enclosure')
    version = item.findtext(ns + 'version') or (enclosure.get(ns + 'version') if enclosure is not None else None)
    if version is None or not version.isdecimal() or int(version) >= int(sys.argv[2]):
        raise SystemExit('The build number must be greater than every published build in the previous feed.')
PY
fi

filename="Triple-$version.dmg"
cp "$dmg" "$stage/$filename"
cp "$notes" "$stage/Triple-$version.md"
"$tools/generate_appcast" \
  --account "$account" \
  --versions "$build" \
  --maximum-versions 0 \
  --maximum-deltas 0 \
  --embed-release-notes \
  --download-url-prefix "https://github.com/$repo/releases/download/$version/" \
  --link "https://github.com/$repo/releases" \
  "$stage"

update_signature="$(python3 - "$stage/appcast.xml" "$scratch/previous.xml" "$build" "$version" "$filename" <<'PY'
import pathlib, sys, xml.etree.ElementTree as ET
feed, previous, build, version, filename = sys.argv[1:]
ns = '{http://www.andymatuschak.org/xml-namespaces/sparkle}'
def items(path):
    result = {}
    for item in ET.parse(path).findall('./channel/item'):
        enclosure = item.find('enclosure')
        key = item.findtext(ns + 'version') or enclosure.get(ns + 'version')
        result[key] = item
    return result
current = items(feed)
if pathlib.Path(previous).exists():
    for key, old in items(previous).items():
        if key not in current or old.find('enclosure').attrib != current[key].find('enclosure').attrib:
            raise SystemExit('A previous release or its download metadata was changed. Do not publish this feed.')
item = current.get(build)
if item is None or item.findtext(ns + 'shortVersionString') != version:
    raise SystemExit('The generated feed does not match the app version.')
if not item.findtext(ns + 'minimumSystemVersion'):
    raise SystemExit('The generated feed is missing its minimum macOS version.')
enclosure = item.find('enclosure')
expected = f'https://github.com/mottzi/TripleApp/releases/download/{version}/{filename}'
if enclosure is None or enclosure.get('url') != expected or not enclosure.get(ns + 'edSignature'):
    raise SystemExit('The generated update download or signature is invalid.')
if int(enclosure.get('length')) != pathlib.Path(feed).with_name(filename).stat().st_size:
    raise SystemExit('The generated update length is invalid.')
if item.find(ns + 'channel') is not None or item.find(ns + 'phasedRolloutInterval') is not None:
    raise SystemExit('Expected an immediate stable release.')
if item.find('description') is None:
    raise SystemExit('The generated feed is missing embedded release notes.')
print(enclosure.get(ns + 'edSignature'))
PY
)"
"$tools/sign_update" --account "$account" --verify "$stage/$filename" "$update_signature"
rm "$stage/Triple-$version.md"
cp "$notes" "$stage/release-notes.md"
(cd "$stage" && /usr/bin/shasum -a 256 "$filename" appcast.xml > SHA256SUMS.txt)
mkdir -p "$(dirname "$output")"
[[ ! -e "$output" ]] || { echo "Output already exists: $output" >&2; exit 1; }
mv "$stage" "$output"
printf 'Prepared release %s, build %s in %s. Nothing has been published.\n' "$version" "$build" "$output"
echo "Test the upgrade, then attach the DMG, appcast.xml, and SHA256SUMS.txt to a draft GitHub release."
