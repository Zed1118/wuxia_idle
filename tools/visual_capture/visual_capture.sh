#!/usr/bin/env bash
# 出版美术视觉验收批量截图:对每个 VISUAL_ROUTE 启动 macOS debug app,
# 等就绪信号 + settle,截"干净窗口"(无桌面/dock),退出。产图到 docs/handoff/。
# 用法:
#   visual_capture.sh                         # 截全部 route × 全部分辨率
#   visual_capture.sh main_menu tech...       # 只截指定 route id
#   visual_capture.sh --res 1920x1080 ...     # 只截指定分辨率(可重复;默认 720p+1080p)
#   visual_capture.sh --dry-run               # 只打印计划不启 app
#
# 截图策略(2026-06-09 重做):用 swift window_id.swift(CGWindowList,零权限)取
# app 窗口 id → screencapture -o -l<id> 截纯窗口。取不到才全屏兜底(-x)。
# 双分辨率:VISUAL_WINDOW_W/H 环境变量传给原生 MainFlutterWindow 强制初始窗口尺寸。
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
SWIFT_WINID="$REPO_ROOT/tools/visual_capture/window_id.swift"

ALL_ROUTES=(main_menu technique_panel_tier_all technique_panel_hero)
DEFAULT_RES=(1280x720 1920x1080)
READY_TIMEOUT=180   # 秒(首跑含编译)
SETTLE=2            # 截图前等图片加载
APP_PROCESS_NAME="wuxia_idle"   # = pubspec name + CGWindow owner name
APP_BIN_MATCH="Debug/Products/Debug/wuxia_idle.app"

DRY_RUN=0
BUILD_MODE=debug   # --profile 出干净 Steam 截图(kDebugMode=false 隐藏 debug chrome)
ROUTES=()
RES=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --profile) BUILD_MODE=profile; shift ;;
    --res) RES+=("$2"); shift 2 ;;
    *) ROUTES+=("$1"); shift ;;
  esac
done
[[ ${#ROUTES[@]} -eq 0 ]] && ROUTES=("${ALL_ROUTES[@]}")
[[ ${#RES[@]} -eq 0 ]] && RES=("${DEFAULT_RES[@]}")

SHA="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
TS="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="docs/handoff/visual_capture_${SHA}_${TS}"
MANIFEST="$OUT_DIR/manifest.txt"

echo "[visual_capture] repo=$REPO_ROOT sha=$SHA"
echo "[visual_capture] routes: ${ROUTES[*]}"
echo "[visual_capture] res:    ${RES[*]}"
echo "[visual_capture] mode:   $BUILD_MODE"
echo "[visual_capture] out: $OUT_DIR"

if [[ $DRY_RUN -eq 1 ]]; then echo "[visual_capture] --dry-run,退出。"; exit 0; fi

mkdir -p "$OUT_DIR"
echo "# visual_capture manifest  sha=$SHA  ts=$TS" > "$MANIFEST"

_kill_stale_app() { pkill -f "$APP_BIN_MATCH" 2>/dev/null || true; sleep 1; }

# swift CGWindowList 取 app 主窗 id(零权限);失败回显空。
_window_id() {
  local err; err="$(mktemp -t vc_winid.XXXXXX)"
  swift "$SWIFT_WINID" "$APP_PROCESS_NAME" >/dev/null 2>"$err" || true
  local best; best="$(grep -o 'BEST=[0-9-]*' "$err" | cut -d= -f2)"
  rm -f "$err"
  [[ "$best" =~ ^[0-9]+$ ]] && echo "$best" || echo ""
}

capture_one() {
  local route="$1" w="$2" h="$3"
  local log; log="$(mktemp -t vc_${route}_${w}x${h}.XXXXXX.log)"
  local png="$OUT_DIR/${route}_${w}x${h}.png"

  echo "[visual_capture] === $route @ ${w}x${h} ==="
  _kill_stale_app
  local mode_flag=""; [[ "$BUILD_MODE" == "profile" ]] && mode_flag="--profile"
  VISUAL_WINDOW_W="$w" VISUAL_WINDOW_H="$h" \
    flutter run -d macos $mode_flag --dart-define=VISUAL_ROUTE="$route" >"$log" 2>&1 &
  local run_pid=$!

  local waited=0 ready=0
  while [[ $waited -lt $READY_TIMEOUT ]]; do
    if grep -q "VISUAL_ROUTE_READY: $route" "$log"; then ready=1; break; fi
    if grep -qE "VISUAL_ROUTE_ERROR|Compilation failed" "$log"; then
      echo "[visual_capture] $route 失败签名,见 $log"; break; fi
    if ! kill -0 "$run_pid" 2>/dev/null; then
      echo "[visual_capture] $route 进程早退,见 $log"; break; fi
    sleep 1; waited=$((waited+1))
  done

  if [[ $ready -eq 1 ]]; then
    sleep "$SETTLE"
    local wid; wid="$(_window_id)"
    if [[ -n "$wid" ]]; then
      if screencapture -o -l"$wid" "$png" 2>/dev/null && [[ -s "$png" ]]; then
        echo "[visual_capture] $route@${w}x${h} 干净窗口 -> $png"
        echo "${route}_${w}x${h} -> ${route}_${w}x${h}.png -> READY(干净窗口 wid=$wid)" >> "$MANIFEST"
      else
        screencapture -x "$png"
        echo "[visual_capture] $route@${w}x${h} -l 失败→全屏兜底 -> $png"
        echo "${route}_${w}x${h} -> ${route}_${w}x${h}.png -> READY(全屏兜底)" >> "$MANIFEST"
      fi
    else
      screencapture -x "$png"
      echo "[visual_capture] $route@${w}x${h} 窗口 id 取失败→全屏兜底 -> $png"
      echo "${route}_${w}x${h} -> ${route}_${w}x${h}.png -> READY(全屏兜底·无 wid)" >> "$MANIFEST"
    fi
  else
    echo "${route}_${w}x${h} -> (无图) -> TIMEOUT/FAIL (log: $log)" >> "$MANIFEST"
    echo "[visual_capture] $route@${w}x${h} 未就绪(${waited}s),跳过。日志 $log"
  fi

  kill "$run_pid" 2>/dev/null || true
  wait "$run_pid" 2>/dev/null || true
  _kill_stale_app
}

for route in "${ROUTES[@]}"; do
  for res in "${RES[@]}"; do
    w="${res%x*}"; h="${res#*x}"
    capture_one "$route" "$w" "$h"
  done
done

echo "[visual_capture] 完成。manifest: $MANIFEST"
cat "$MANIFEST"
