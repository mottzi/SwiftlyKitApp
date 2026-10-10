#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 1 ]] || { echo "Usage: $0 /path/to/signed.app" >&2; exit 2; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Read the signed entitlements, rather than the build's source entitlement file.
# pipefail also rejects an unreadable or unsigned app even if stdout is empty.
/usr/bin/codesign --display --entitlements - --xml "$1" |
  python3 "$root/script/release_validation.py" entitlements
