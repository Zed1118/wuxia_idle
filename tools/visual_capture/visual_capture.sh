#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SWIFT_WINID="$REPO_ROOT/tools/visual_capture/window_id.swift"
APP_PROCESS_NAME="wuxia_idle"

SUITE="smoke"
OUTPUT_DIR="build/visual_acceptance"
RESOLUTIONS="1280x720,1440x900,1920x1080,2560x1080"
ROUTE=""
DRY_RUN=0
HITBOX=0
WAIT_SECONDS=12
READY_TIMEOUT=90

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
  --ready-timeout <seconds>  Seconds to wait for VISUAL_ROUTE_READY. Default: 90.
  --dry-run                  Print planned commands only.
  -h, --help                 Show this help.

Notes:
  - Uses only local Flutter/macOS tools and screencapture.
  - VISUAL_WINDOW_W/H locks the native macOS window before Flutter starts.
  - Captures the app window by CGWindowID; falls back to region capture.
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
    --ready-timeout)
      READY_TIMEOUT="$2"
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

resize_visual_window() {
  local width="$1"
  local height="$2"
  osascript <<OSA
tell application "System Events"
  set candidates to {"wuxia_idle", "挂机武侠", "Runner"}
  repeat with appName in candidates
    if exists application process (appName as text) then
      set appProc to application process (appName as text)
      set frontmost of appProc to true
      if (count of windows of appProc) > 0 then
        set position of front window of appProc to {0, 0}
        set size of front window of appProc to {$width, $height}
        return
      end if
    end if
  end repeat
  error "No visual app window found"
end tell
OSA
}

capture_region() {
  local width="$1"
  local height="$2"
  local output="$3"
  screencapture -x -R"0,0,$width,$height" "$output"
}

window_id() {
  local err
  err="$(mktemp -t vc_winid.XXXXXX)"
  swift "$SWIFT_WINID" "$APP_PROCESS_NAME" >/dev/null 2>"$err" || true
  local best
  best="$(grep -o 'BEST=[0-9-]*' "$err" | cut -d= -f2)"
  rm -f "$err"
  if [[ "$best" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$best"
  fi
}

capture_visual_window() {
  local width="$1"
  local height="$2"
  local output="$3"
  local wid
  wid="$(window_id)"
  if [[ -n "$wid" ]] && screencapture -x -o -l"$wid" "$output" >/dev/null 2>&1 && [[ -s "$output" ]]; then
    printf 'window_id:%s\n' "$wid"
    return 0
  fi
  capture_region "$width" "$height" "$output"
  printf 'fallback_region\n'
}

focus_visual_app() {
  osascript <<'OSA'
tell application "System Events"
  set candidates to {"wuxia_idle", "挂机武侠", "Runner"}
  repeat with appName in candidates
    if exists application process (appName as text) then
      set frontmost of application process (appName as text) to true
      return
    end if
  end repeat
end tell
OSA
}

terminate_visual_app() {
  osascript <<OSA >/dev/null 2>&1 || true
tell application "System Events"
  if exists application process "$APP_PROCESS_NAME" then
    tell application "$APP_PROCESS_NAME" to quit
  end if
end tell
OSA
  local elapsed=0
  while [[ "$elapsed" -lt 5 ]]; do
    if ! pgrep -x "$APP_PROCESS_NAME" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  pkill -x "$APP_PROCESS_NAME" >/dev/null 2>&1 || true
}

wait_for_route_ready() {
  local route="$1"
  local log="$2"
  local elapsed=0
  while [[ "$elapsed" -lt "$READY_TIMEOUT" ]]; do
    if grep -q "VISUAL_ROUTE_READY: $route" "$log" 2>/dev/null; then
      return 0
    fi
    if grep -q "VISUAL_ROUTE_ERROR: $route" "$log" 2>/dev/null; then
      return 1
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  return 1
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
    printf '[dry-run] VISUAL_WINDOW_W=%s VISUAL_WINDOW_H=%s; window-id capture %s\n' "$width" "$height" "$png"
    return
  fi

  terminate_visual_app

  VISUAL_WINDOW_W="$width" VISUAL_WINDOW_H="$height" \
    "${cmd[@]}" >"$log" 2>&1 < /dev/null &
  local pid=$!
  if ! wait_for_route_ready "$route" "$log"; then
    echo "Route did not become ready: $route (see $log)" >&2
    kill "$pid" >/dev/null 2>&1 || true
    wait "$pid" >/dev/null 2>&1 || true
    return 1
  fi
  sleep "$WAIT_SECONDS"
  focus_visual_app >>"$log" 2>&1 || printf 'VISUAL_CAPTURE_WARN: focus_failed\n' >>"$log"
  sleep 1
  resize_visual_window "$width" "$height" >>"$log" 2>&1 || printf 'VISUAL_CAPTURE_WARN: resize_failed\n' >>"$log"
  sleep 1
  focus_visual_app >>"$log" 2>&1 || printf 'VISUAL_CAPTURE_WARN: focus_failed\n' >>"$log"
  sleep 1
  local capture_status
  capture_status="$(capture_visual_window "$width" "$height" "$png")"
  kill "$pid" >/dev/null 2>&1 || true
  wait "$pid" >/dev/null 2>&1 || true
  printf 'VISUAL_CAPTURE: %s\n' "$capture_status" >>"$log"
}

IFS=',' read -r -a resolution_list <<< "$RESOLUTIONS"
while IFS= read -r route; do
  [[ -z "$route" ]] && continue
  for resolution in "${resolution_list[@]}"; do
    run_capture "$route" "$resolution"
  done
done < <(route_ids)
