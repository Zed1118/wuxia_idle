#!/usr/bin/env bash
set -euo pipefail

SUITE="smoke"
OUTPUT_DIR="build/visual_acceptance"
RESOLUTIONS="1280x720,1440x900,1920x1080,2560x1080"
ROUTE=""
DRY_RUN=0
HITBOX=0
WAIT_SECONDS=12

usage() {
  cat <<'USAGE'
Local visual route screenshot helper.

Usage:
  tools/visual_capture/visual_capture.sh [options]

Options:
  --suite smoke|full         Route suite from tool/visual_acceptance.dart.
  --route <id>               Capture one route instead of the suite.
  --resolutions <csv>        Window sizes, e.g. 1280x720,1920x1080.
  --output <dir>             Output directory. Default: build/visual_acceptance.
  --hitbox                   Enable debug hitbox overlay.
  --wait <seconds>           Seconds to wait after launch before screenshot.
  --dry-run                  Print planned commands only.
  -h, --help                 Show this help.

Notes:
  - Uses only local Flutter/macOS tools and screencapture.
  - Captures the front macOS window after resizing it with AppleScript.
  - Output path pattern: <output>/<suite-or-route>/<resolution>/<route>.png
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --suite)
      SUITE="$2"
      shift 2
      ;;
    --route)
      ROUTE="$2"
      shift 2
      ;;
    --resolutions)
      RESOLUTIONS="$2"
      shift 2
      ;;
    --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --hitbox)
      HITBOX=1
      shift
      ;;
    --wait)
      WAIT_SECONDS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

route_ids() {
  if [[ -n "$ROUTE" ]]; then
    printf '%s\n' "$ROUTE"
  else
    flutter pub run tool/visual_acceptance.dart routes \
      --suite "$SUITE" \
      --format ids
  fi
}

resize_front_window() {
  local width="$1"
  local height="$2"
  osascript <<OSA
tell application "System Events"
  set frontApp to first application process whose frontmost is true
  set position of front window of frontApp to {0, 0}
  set size of front window of frontApp to {$width, $height}
end tell
OSA
}

capture_front_window() {
  local output="$1"
  osascript <<'OSA' | tr -d '\n' | xargs -I{} screencapture -x -o -l {} "$output"
tell application "System Events"
  set frontApp to first application process whose frontmost is true
  set winId to value of attribute "AXWindowNumber" of front window of frontApp
  return winId
end tell
OSA
}

run_capture() {
  local route="$1"
  local resolution="$2"
  local width="${resolution%x*}"
  local height="${resolution#*x}"
  local group="${ROUTE:-$SUITE}"
  local dir="$OUTPUT_DIR/$group/$resolution"
  local png="$dir/$route.png"
  local log="$dir/$route.log"
  local hitbox_define="false"
  if [[ "$HITBOX" -eq 1 ]]; then
    hitbox_define="true"
  fi

  mkdir -p "$dir"

  local cmd=(
    flutter run -d macos
    --dart-define=VISUAL_ROUTE="$route"
    --dart-define=HITBOX_DEBUG="$hitbox_define"
  )

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %s\n' "${cmd[*]}"
    printf '[dry-run] resize %sx%s; capture %s\n' "$width" "$height" "$png"
    return
  fi

  "${cmd[@]}" >"$log" 2>&1 &
  local pid=$!
  sleep "$WAIT_SECONDS"
  resize_front_window "$width" "$height"
  sleep 1
  capture_front_window "$png"
  kill "$pid" >/dev/null 2>&1 || true
  wait "$pid" >/dev/null 2>&1 || true
}

IFS=',' read -r -a resolution_list <<< "$RESOLUTIONS"
while IFS= read -r route; do
  [[ -z "$route" ]] && continue
  for resolution in "${resolution_list[@]}"; do
    run_capture "$route" "$resolution"
  done
done < <(route_ids)
