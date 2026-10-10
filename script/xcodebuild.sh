#!/usr/bin/env bash
set -euo pipefail

# The workspace overrides Triple with the local sources for development.
# The standalone project resolves the pinned GitHub dependency for releases.
exec xcodebuild "$@"
