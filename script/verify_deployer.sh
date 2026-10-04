#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 || ! -f "$1/Package.swift" ]]; then
    echo "Usage: $0 /path/to/Vapor-Deployer" >&2
    exit 2
fi

package_root=$(cd "$1" && pwd -P)
repository_root=$(cd "$(dirname "$0")/.." && pwd -P)
derived_data="$repository_root/.derivedData/deployer-verification"
cd "$repository_root"

xcodebuild build-for-testing \
    -workspace SwiftlyKitApp.xcworkspace \
    -scheme SwiftlyKitApp \
    -destination 'platform=macOS' \
    -derivedDataPath "$derived_data"

test_run="$derived_data/Build/Products/SwiftlyKitApp-Deployer.xctestrun"
python3 - "$derived_data/Build/Products" "$package_root" "$test_run" <<'PY'
import pathlib
import plistlib
import sys

products, package, destination = sys.argv[1:]
sources = [path for path in pathlib.Path(products).glob("*.xctestrun") if path.name != pathlib.Path(destination).name]
if len(sources) != 1:
    raise SystemExit(f"Expected one generated test configuration, found {len(sources)}")
with sources[0].open("rb") as stream:
    configuration = plistlib.load(stream)
for test_configuration in configuration["TestConfigurations"]:
    for target in test_configuration["TestTargets"]:
        for key in ("EnvironmentVariables", "TestingEnvironmentVariables"):
            target.setdefault(key, {})["SWIFTLYKIT_DEPLOYER_PACKAGE"] = package
with open(destination, "wb") as stream:
    plistlib.dump(configuration, stream)
PY

xcodebuild test-without-building \
    -xctestrun "$test_run" \
    -destination 'platform=macOS' \
    -only-testing:SwiftlyKitAppTests/HostSDKAcceptanceTests
