#!/usr/bin/env bash
# 出版美术视觉验收批量截图:对每个 VISUAL_ROUTE 启动 macOS debug app,
# 等就绪信号 + settle,截 Flutter 窗口,退出。产图到 docs/handoff/。
# 用法:
#   visual_capture.sh                         # 截全部 route
#   visual_capture.sh main_menu tech...       # 只截指定 route id
#   visual_capture.sh --dry-run               # 只打印计划不启 app
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

ALL_ROUTES=(main_menu technique_panel_tier_all technique_panel_hero)
READY_TIMEOUT=120   # 秒
SETTLE=2            # 截图前等图片加载

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

capture_one() {
  local route="$1"
  local log; log="$(mktemp -t vc_${route}.XXXXXX.log)"
  local png="$OUT_DIR/${route}.png"

  echo "[visual_capture] === $route ==="
  flutter run -d macos --dart-define=VISUAL_ROUTE="$route" >"$log" 2>&1 &
  local run_pid=$!

  local waited=0 ready=0
  while [[ $waited -lt $READY_TIMEOUT ]]; do
    if grep -q "VISUAL_ROUTE_READY: $route" "$log"; then ready=1; break; fi
    if grep -qE "VISUAL_ROUTE_ERROR|Exception|Error:|Failed to|Compilation failed" "$log"; then
      echo "[visual_capture] $route 失败签名,见 $log"; break
    fi
    if ! kill -0 "$run_pid" 2>/dev/null; then
      echo "[visual_capture] $route 进程早退,见 $log"; break
    fi
    sleep 1; waited=$((waited+1))
  done

  if [[ $ready -eq 1 ]]; then
    sleep "$SETTLE"
    local wid
    wid="$(osascript -e 'tell application "System Events" to tell (first process whose frontmost is true) to id of front window' 2>/dev/null || echo "")"
    if [[ -n "$wid" ]]; then
      screencapture -l"$wid" -o "$png" 2>/dev/null || screencapture -o "$png"
    else
      echo "[visual_capture] $route 窗口 id 取失败,用交互全屏(请框选)"; screencapture -o "$png"
    fi
    echo "$route -> ${route}.png -> READY" >> "$MANIFEST"
    echo "[visual_capture] $route 截图 -> $png"
  else
    echo "$route -> (无图) -> TIMEOUT/FAIL (log: $log)" >> "$MANIFEST"
    echo "[visual_capture] $route 未就绪(${waited}s),跳过截图。"
  fi

  kill "$run_pid" 2>/dev/null || true
  wait "$run_pid" 2>/dev/null || true
}

for route in "${ROUTES[@]}"; do
  capture_one "$route"
done

echo "[visual_capture] 完成。manifest: $MANIFEST"
cat "$MANIFEST"
