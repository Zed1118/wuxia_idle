#!/usr/bin/env bash
# 出版美术视觉验收批量截图:对每个 VISUAL_ROUTE 启动 macOS debug app,
# 等就绪信号 + settle,截图,退出。产图到 docs/handoff/。
# 用法:
#   visual_capture.sh                         # 截全部 route
#   visual_capture.sh main_menu tech...       # 只截指定 route id
#   visual_capture.sh --dry-run               # 只打印计划不启 app
#
# 截图策略:优先按 app 进程名取窗口 id 截干净窗口(需「辅助功能」权限授给
# 运行本脚本的终端);取不到则**非交互全屏兜底**(零权限、不卡,图含桌面杂物,
# 读图时看 app 窗口区域即可)。每个 route 启动前先清残留 app 窗口防截错窗。
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

ALL_ROUTES=(main_menu technique_panel_tier_all technique_panel_hero)
READY_TIMEOUT=180   # 秒(首跑含编译)
SETTLE=2            # 截图前等图片加载
APP_PROCESS_NAME="wuxia_idle"   # = pubspec name,flutter run 起的 macOS debug app 名
APP_BIN_MATCH="Debug/Products/Debug/wuxia_idle.app"

DRY_RUN=0
ROUTES=()
for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then DRY_RUN=1; else ROUTES+=("$arg"); fi
done
[[ ${#ROUTES[@]} -eq 0 ]] && ROUTES=("${ALL_ROUTES[@]}")

SHA="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
TS="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="docs/handoff/visual_capture_${SHA}_${TS}"
MANIFEST="$OUT_DIR/manifest.txt"

echo "[visual_capture] repo=$REPO_ROOT sha=$SHA"
echo "[visual_capture] routes: ${ROUTES[*]}"
echo "[visual_capture] out: $OUT_DIR"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[visual_capture] --dry-run,退出。"
  exit 0
fi

mkdir -p "$OUT_DIR"
echo "# visual_capture manifest  sha=$SHA  ts=$TS" > "$MANIFEST"

_kill_stale_app() {
  pkill -f "$APP_BIN_MATCH" 2>/dev/null || true
  sleep 1
}

# 尝试取 app 前窗 id(需辅助功能权限);失败返回空。
_front_window_id() {
  osascript -e "tell application \"System Events\" to set frontmost of (first process whose name is \"$APP_PROCESS_NAME\") to true" >/dev/null 2>&1 || true
  sleep 0.8
  osascript -e "tell application \"System Events\" to tell (first process whose name is \"$APP_PROCESS_NAME\") to id of front window" 2>/dev/null || echo ""
}

capture_one() {
  local route="$1"
  local log; log="$(mktemp -t vc_${route}.XXXXXX.log)"
  local png="$OUT_DIR/${route}.png"

  echo "[visual_capture] === $route ==="
  _kill_stale_app   # 清残留窗口,防截错窗
  flutter run -d macos --dart-define=VISUAL_ROUTE="$route" >"$log" 2>&1 &
  local run_pid=$!

  local waited=0 ready=0
  while [[ $waited -lt $READY_TIMEOUT ]]; do
    if grep -q "VISUAL_ROUTE_READY: $route" "$log"; then ready=1; break; fi
    if grep -qE "VISUAL_ROUTE_ERROR|Exception|Error:|Compilation failed" "$log"; then
      echo "[visual_capture] $route 失败签名,见 $log"; break
    fi
    if ! kill -0 "$run_pid" 2>/dev/null; then
      echo "[visual_capture] $route 进程早退,见 $log"; break
    fi
    sleep 1; waited=$((waited+1))
  done

  if [[ $ready -eq 1 ]]; then
    sleep "$SETTLE"
    local wid; wid="$(_front_window_id)"
    if [[ "$wid" =~ ^[0-9]+$ ]]; then
      screencapture -l"$wid" "$png" 2>/dev/null && echo "[visual_capture] $route 窗口截图 -> $png" \
        || { screencapture -x "$png"; echo "[visual_capture] $route 窗口截失败→全屏 $png"; }
      echo "$route -> ${route}.png -> READY(窗口)" >> "$MANIFEST"
    else
      # 非交互全屏兜底(零权限不卡;唯一 app 窗口已在前,图含桌面杂物)
      screencapture -x "$png"
      echo "[visual_capture] $route 窗口 id 取失败→非交互全屏兜底 -> $png"
      echo "$route -> ${route}.png -> READY(全屏兜底)" >> "$MANIFEST"
    fi
  else
    echo "$route -> (无图) -> TIMEOUT/FAIL (log: $log)" >> "$MANIFEST"
    echo "[visual_capture] $route 未就绪(${waited}s),跳过截图。日志 $log"
  fi

  kill "$run_pid" 2>/dev/null || true
  wait "$run_pid" 2>/dev/null || true
  _kill_stale_app
}

for route in "${ROUTES[@]}"; do
  capture_one "$route"
done

echo "[visual_capture] 完成。manifest: $MANIFEST"
cat "$MANIFEST"
