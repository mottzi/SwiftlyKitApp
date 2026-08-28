#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="SwiftlyKitApp"
BUNDLE_ID="codes.mottzi.SwiftlyKitApp"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/.derivedData"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Debug/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

app_is_running() {
  pgrep -x "$APP_NAME" >/dev/null 2>&1
}

app_owned_by_xcode() {
  local pid parent_pid parent_command

  while read -r pid; do
    [[ -n "$pid" ]] || continue

    parent_pid="$(ps -o ppid= -p "$pid" | tr -d '[:space:]')"
    parent_command="$(ps -o command= -p "$parent_pid")"
    if [[ "$parent_command" == *debugserver* ]]; then
      return 0
    fi

    if ps eww -p "$pid" -o command= | grep -q '__XCODE_BUILT_PRODUCTS_DIR_PATHS='; then
      return 0
    fi
  done < <(pgrep -x "$APP_NAME" || true)

  return 1
}

wait_for_app_to_exit() {
  local deadline=$((SECONDS + 10))

  while app_is_running; do
    if (( SECONDS >= deadline )); then
      return 1
    fi
    sleep 0.1
  done
}

wait_for_xcode_app_to_exit() {
  local deadline=$((SECONDS + 10))

  while app_owned_by_xcode; do
    if (( SECONDS >= deadline )); then
      return 1
    fi
    sleep 0.1
  done
}

stop_xcode_run() {
  local xcode_action

  if ! xcode_action="$(osascript <<'APPLESCRIPT'
if application "Xcode" is not running then
  return "not-running"
end if

tell application "Xcode"
  try
    set workspaceDocument to workspace document "SwiftlyKitApp.xcodeproj"
  on error
    return "not-open"
  end try

  stop workspaceDocument
  return "stop-sent"
end tell
APPLESCRIPT
)"; then
    echo "Could not ask Xcode about its SwiftlyKitApp run session." >&2
    return 1
  fi

  case "$xcode_action" in
    stop-sent|not-running|not-open)
      ;;
    error:*)
      echo "Could not stop the Xcode run session: ${xcode_action#error:}" >&2
      return 1
      ;;
    *)
      echo "Xcode returned an unknown run state: $xcode_action" >&2
      return 1
      ;;
  esac
}

stop_existing_app() {
  if ! app_is_running; then
    return
  fi

  local xcode_owned=false
  if app_owned_by_xcode; then
    xcode_owned=true
  fi

  stop_xcode_run

  if [[ "$xcode_owned" == true ]] && ! wait_for_xcode_app_to_exit; then
    echo "Xcode did not stop $APP_NAME within 10 seconds; refusing to kill it." >&2
    return 1
  fi

  if app_is_running; then
    pkill -x "$APP_NAME" >/dev/null 2>&1 || true
    if ! wait_for_app_to_exit; then
      echo "$APP_NAME did not exit within 10 seconds; refusing to launch another instance." >&2
      return 1
    fi
  fi
}

stop_existing_app

xcodebuild \
  -project "$ROOT_DIR/SwiftlyKitApp.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  build

open_app() {
  /usr/bin/open "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
