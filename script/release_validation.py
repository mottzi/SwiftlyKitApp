#!/usr/bin/env python3
"""Checks shared by distribution scripts, without signing or publishing."""

import json
import plistlib
import re
import sys


def check_entitlements(data):
    # codesign emits no plist when the signature has no entitlements.
    if not data.strip():
        return
    entitlements = plistlib.loads(data)
    if not isinstance(entitlements, dict):
        raise ValueError("The signed entitlements must be a dictionary.")
    if entitlements.get("com.apple.security.get-task-allow", False) is not False:
        raise ValueError("A distributable app must not enable get-task-allow.")


def version_parts(value):
    if not re.fullmatch(r"\d+\.\d+(?:\.\d+)?", value):
        raise ValueError("Use stable numeric release versions.")
    parts = tuple(map(int, value.split(".")))
    return parts + (0,) * (3 - len(parts))


def check_version(latest, version, build):
    if version_parts(version) <= version_parts(latest.removeprefix("v")):
        raise ValueError("Increment the marketing version above the latest public release before preparing an update.")
    if not re.fullmatch(r"[1-9][0-9]*", build) or int(build) <= 2:
        raise ValueError("The build number must exceed the last pre-Sparkle public build, 2.")


if __name__ == "__main__":
    try:
        if len(sys.argv) == 2 and sys.argv[1] == "entitlements":
            check_entitlements(sys.stdin.buffer.read())
        elif len(sys.argv) == 5 and sys.argv[1] == "version":
            with open(sys.argv[2]) as source:
                check_version(json.load(source)["tagName"], sys.argv[3], sys.argv[4])
        else:
            raise ValueError("Usage: release_validation.py entitlements | version latest.json version build")
    except (ValueError, plistlib.InvalidFileException, KeyError) as error:
        raise SystemExit(str(error))
