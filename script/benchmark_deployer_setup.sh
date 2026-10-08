#!/bin/bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 || ! -f "$1/Package.swift" ]]; then
    echo "Usage: $0 /path/to/Vapor-Deployer [maximum-seconds-per-run]" >&2
    exit 2
fi

package_root=$(cd "$1" && pwd -P)
repository_root=$(cd "$(dirname "$0")/.." && pwd -P)
derived_data="$repository_root/.derivedData/deployer-verification"
timings=$(mktemp /tmp/swiftlykit-configuration-timings.XXXXXX)
cd "$repository_root"

xcodebuild build-for-testing -quiet \
    -workspace SwiftlyKitApp.xcworkspace -scheme SwiftlyKitApp \
    -destination 'platform=macOS' -derivedDataPath "$derived_data"

test_run="$derived_data/Build/Products/SwiftlyKitApp-Configuration.xctestrun"
python3 - "$derived_data/Build/Products" "$package_root" "$test_run" "$timings" "${2:-}" <<'PY'
import pathlib
import plistlib
import sys

products, package, destination, timings, limit = sys.argv[1:]
sources = [p for p in pathlib.Path(products).glob("*.xctestrun") if p.name.startswith("SwiftlyKitApp_SwiftlyKitApp_")]
if len(sources) != 1:
    raise SystemExit(f"Expected one generated test configuration, found {len(sources)}")
with sources[0].open("rb") as stream:
    configuration = plistlib.load(stream)
values = {
    "SWIFTLYKIT_CONFIGURATION_BENCHMARK": "1",
    "SWIFTLYKIT_DEPLOYER_PACKAGE": package,
    "SWIFTLYKIT_CONFIGURATION_TIMINGS": timings,
}
if limit:
    values["SWIFTLYKIT_CONFIGURATION_MAX_SECONDS"] = limit
for test_configuration in configuration["TestConfigurations"]:
    for target in test_configuration["TestTargets"]:
        for key in ("EnvironmentVariables", "TestingEnvironmentVariables"):
            target.setdefault(key, {}).update(values)
with open(destination, "wb") as stream:
    plistlib.dump(configuration, stream)
PY

if xcodebuild test-without-building -quiet \
    -xctestrun "$test_run" -destination 'platform=macOS' \
    '-only-testing:SwiftlyKitAppTests/ConfigurationTimingTests/selectionTiming()'; then
    benchmark_status=0
else
    benchmark_status=$?
fi
cat "$timings"
echo "Timing evidence: $timings"
exit "$benchmark_status"
