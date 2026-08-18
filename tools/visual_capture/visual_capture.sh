#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SWIFT_WINID="$REPO_ROOT/tools/visual_capture/window_id.swift"
CROP_CONTENT="$REPO_ROOT/tools/visual_capture/crop_window_content.py"
LOCK_STATE_HELPER="$REPO_ROOT/tools/visual_capture/lock_state.py"
FIDELITY_ANALYZER="$REPO_ROOT/tools/visual_capture/analyze_battle_v2_fidelity.py"
APP_PROCESS_NAME="wuxia_idle"
APP_EXECUTABLE="$REPO_ROOT/build/macos/Build/Products/Debug/wuxia_idle.app/Contents/MacOS/wuxia_idle"

SUITE="smoke"
OUTPUT_DIR="build/visual_acceptance"
RESOLUTIONS="1280x720,1440x900,1920x1080,2560x1080"
ROUTE=""
# --route 缺省时接受 VISUAL_ROUTE 环境变量兜底(2026-07-05 诊断批 deferred 项:
# plan/handoff 文档曾误写 `VISUAL_ROUTE=<id> bash ...` 传法,加兼容防复发;
# flag 显式给出时以 flag 为准)。
ENV_ROUTE_FALLBACK="${VISUAL_ROUTE:-}"
DRY_RUN=0
HITBOX=0
WAIT_SECONDS=12
READY_TIMEOUT=90
ALL_SPACES=0
EXISTING_WINDOW=0
PREBUILT=1
BACKGROUND=0
WRITE_MANIFEST=1

usage() {
  cat <<'USAGE'
Local visual route screenshot helper.

Usage:
  tools/visual_capture/visual_capture.sh [options]

Options:
  --suite smoke|battle|full  Route suite from tool/visual_acceptance.dart.
  --route <id>               Capture one route instead of the suite.
  --resolutions <csv>        Window sizes, e.g. 1280x720,1920x1080.
  --output <dir>             Output directory. Default: build/visual_acceptance.
  --hitbox                   Enable debug hitbox overlay.
  --wait <seconds>           Seconds to wait after launch before screenshot.
  --ready-timeout <seconds>  Seconds to wait for VISUAL_ROUTE_READY. Default: 90.
  --all-spaces              Find the app window across all macOS Spaces.
  --existing-window         Capture an already-running window; do not launch,
                            focus, resize, or terminate the app.
  --no-prebuilt             Use legacy per-route flutter run instead of one
                            prebuilt debug app with runtime route arguments.
  --background              Do not focus or resize the app; capture its window
                            by CGWindowID across Spaces (window env locks size).
  --no-manifest             Do not write <output>/fidelity_manifest.json.
  --dry-run                  Print planned commands only.
  -h, --help                 Show this help.

Notes:
  - VISUAL_ROUTE env var is accepted as a fallback for --route (the flag
    wins if both are given). The value still becomes a compile-time
    dart-define per route; exporting VISUAL_ROUTE alone without this
    script has no effect on a prebuilt app.
  - Uses only local Flutter/macOS tools and screencapture.
  - VISUAL_WINDOW_W/H locks the native macOS window before Flutter starts.
  - Captures the app window by CGWindowID; falls back to region capture.
  - Use --existing-window --all-spaces for background capture from another
    desktop without switching Spaces or stealing focus.
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
    --all-spaces)
      ALL_SPACES=1
      shift
      ;;
    --existing-window)
      EXISTING_WINDOW=1
      shift
      ;;
    --no-prebuilt)
      PREBUILT=0
      shift
      ;;
    --background)
      BACKGROUND=1
      ALL_SPACES=1
      shift
      ;;
    --no-manifest)
      WRITE_MANIFEST=0
      shift
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

if [[ -z "$ROUTE" && -n "$ENV_ROUTE_FALLBACK" ]]; then
  ROUTE="$ENV_ROUTE_FALLBACK"
  echo "note: --route not given, using VISUAL_ROUTE env fallback: $ROUTE" >&2
fi

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

# 截图/锁屏判定函数已抽至 visual_capture_lib.sh(2026-08-18,为行为测可注入);
# lib 依赖本脚本已定义的 REPO_ROOT/SWIFT_WINID/LOCK_STATE_HELPER/APP_PROCESS_NAME。
source "$REPO_ROOT/tools/visual_capture/visual_capture_lib.sh"

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

  if [[ "$EXISTING_WINDOW" -eq 1 ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '[dry-run] existing-window capture all_spaces=%s %s\n' "$ALL_SPACES" "$png"
      return
    fi
    local existing_wid
    existing_wid="$(window_id)"
    if [[ -z "$existing_wid" ]]; then
      echo "Existing visual window not found (all_spaces=$ALL_SPACES)" >&2
      return 1
    fi
    if ! screencapture -x -o -l"$existing_wid" "$png" >/dev/null 2>&1 || [[ ! -s "$png" ]]; then
      echo "Failed to capture existing visual window id=$existing_wid" >&2
      return 1
    fi
    {
      printf 'VISUAL_CAPTURE: existing_window_id:%s\n' "$existing_wid"
      printf 'VISUAL_CAPTURE_ALL_SPACES: %s\n' "$ALL_SPACES"
    } >"$log"
    return
  fi

  local cmd
  if [[ "$PREBUILT" -eq 1 ]]; then
    cmd=("$APP_EXECUTABLE" "--visual-route=$route")
  else
    cmd=(
      flutter run -d macos
      --dart-define=VISUAL_ROUTE="$route"
      --dart-define=HITBOX_DEBUG="$hitbox_define"
      --dart-define=VISUAL_FIDELITY_PROBE=true
    )
  fi

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
    stop_pid "$pid" "$log"
    return 1
  fi
  sleep "$WAIT_SECONDS"
  if [[ "$BACKGROUND" -eq 0 ]]; then
    focus_visual_app >>"$log" 2>&1 || printf 'VISUAL_CAPTURE_WARN: focus_failed\n' >>"$log"
    sleep 1
    resize_visual_window "$width" "$height" >>"$log" 2>&1 || printf 'VISUAL_CAPTURE_WARN: resize_failed\n' >>"$log"
    sleep 1
    focus_visual_app >>"$log" 2>&1 || printf 'VISUAL_CAPTURE_WARN: focus_failed\n' >>"$log"
    sleep 1
  fi
  local capture_status capture_rc=0
  capture_status="$(capture_visual_window "$width" "$height" "$png" "$pid" "$log")" || capture_rc=$?
  if [[ "$capture_rc" -eq 0 ]]; then
    python3 "$CROP_CONTENT" "$png" \
      --logical-width "$width" \
      --logical-height "$height" >>"$log"
  fi
  stop_pid "$pid" "$log"
  printf 'VISUAL_CAPTURE: %s\n' "$capture_status" >>"$log"
  if [[ "$capture_rc" -ne 0 ]]; then
    local lock_word
    case "$capture_status" in
      *lock=locked)   lock_word="是" ;;
      *lock=unlocked) lock_word="否" ;;
      *)              lock_word="未知" ;;
    esac
    printf 'VISUAL_CAPTURE_FAIL: 窗口截图与区域截图均失败;会话锁屏=%s ⇒ 无人值守时段无法采集视觉证据,请在解锁会话下重跑\n' "$lock_word" >>"$log"
    printf '窗口截图与区域截图均失败;会话锁屏=%s ⇒ 无人值守时段无法采集视觉证据,请在解锁会话下重跑(route=%s, log=%s)\n' "$lock_word" "$route" "$log" >&2
    return 1
  fi
}

IFS=',' read -r -a resolution_list <<< "$RESOLUTIONS"
if [[ "$EXISTING_WINDOW" -eq 0 && "$PREBUILT" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
  hitbox_define="false"
  if [[ "$HITBOX" -eq 1 ]]; then
    hitbox_define="true"
  fi
  flutter build macos --debug \
    --dart-define=HITBOX_DEBUG="$hitbox_define" \
    --dart-define=VISUAL_FIDELITY_PROBE=true
fi
while IFS= read -r route; do
  [[ -z "$route" ]] && continue
  for resolution in "${resolution_list[@]}"; do
    run_capture "$route" "$resolution"
  done
done < <(route_ids)

if [[ "$WRITE_MANIFEST" -eq 1 ]]; then
  manifest_path="$OUTPUT_DIR/fidelity_manifest.json"
  commit="$(git -C "$REPO_ROOT" rev-parse HEAD)"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] write fidelity manifest commit=%s %s\n' "$commit" "$manifest_path"
  else
    # --repo-root records the working-tree git tree id and a dirty flag.
    # Captures are usually taken before the edits are committed, so commit
    # alone names the previous code state and cannot pin what was rendered.
    python3 "$FIDELITY_ANALYZER" \
      --capture-root "$OUTPUT_DIR" \
      --commit "$commit" \
      --repo-root "$REPO_ROOT" \
      --write-manifest "$manifest_path"
    printf 'fidelity manifest: %s\n' "$manifest_path"
  fi
fi
