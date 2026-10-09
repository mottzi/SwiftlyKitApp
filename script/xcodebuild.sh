#!/usr/bin/env bash
set -euo pipefail

# Resolve the pinned Triple revision from the sibling checkout during development.
# The intended remote URL and release pin stay in the Xcode project.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
library="$root/../SwiftlyKit"
if [[ -f "$library/Package.swift" ]] && grep -q 'name: "Triple"' "$library/Package.swift"; then
  library="$(git -C "$library" rev-parse --show-toplevel)"
  count="${GIT_CONFIG_COUNT:-0}"
  export "GIT_CONFIG_KEY_$count=url.$library.insteadOf"
  export "GIT_CONFIG_VALUE_$count=https://github.com/mottzi/Triple.git"
  export GIT_CONFIG_COUNT="$((count + 1))"
fi

exec xcodebuild "$@"
