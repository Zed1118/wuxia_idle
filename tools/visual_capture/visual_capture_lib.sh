#!/usr/bin/env bash
# visual_capture.sh 的截图/锁屏判定函数库(2026-08-18 从主脚本抽出,为行为测可注入)。
#
# 本文件只定义函数,不产生副作用;依赖以下全局由调用方(source 它的主脚本或测试)提供:
#   SWIFT_WINID / LOCK_STATE_HELPER / APP_PROCESS_NAME / ALL_SPACES
# 测试可覆写依赖(如 LOCK_STATE_HELPER="" 让默认值兜底)并往 PATH 注 screencapture/swift stub。
#
# 锁屏语义(2026-08-12 audit 定谳,docs/audit/visual_capture_lock_rect_failure_2026-08-12.md):
# 锁屏时 screencapture -R 必死且 osascript 摆不了窗口((0,0,W,H) 几何前提不成立),
# 区域 fallback 救不出正确画面——「明着失败」永远优于「看似成功的错图」。

capture_region() {
  local width="$1"
  local height="$2"
  local output="$3"
  screencapture -x -R"0,0,$width,$height" "$output"
}

window_id() {
  # $1(可选)= 本次启动的 app pid。传了就只认该进程的窗口——同名残留进程
  # (TERM 免疫僵尸)的旧窗与新窗面积并列时,纯按名+面积会截出前一 route 的
  # 画面(2026-08-04 批 C cycle 720 错拍实锤),绑 pid 根除。
  local owner_pid="${1:-}"
  local err
  err="$(mktemp -t vc_winid.XXXXXX)"
  local args=("$SWIFT_WINID" "$APP_PROCESS_NAME")
  if [[ -n "$owner_pid" ]]; then
    args+=(--pid "$owner_pid")
  fi
  if [[ "$ALL_SPACES" -eq 1 ]]; then
    args+=(--all-spaces)
  fi
  swift "${args[@]}" >/dev/null 2>"$err" || true
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
  local owner_pid="${4:-}"
  local log="${5:-}"
  local wid lock_state win_rc=0 win_bytes=0 region_rc=0
  wid="$(window_id "$owner_pid")"
  if [[ -n "$wid" ]]; then
    screencapture -x -o -l"$wid" "$output" >/dev/null 2>&1 || win_rc=$?
    win_bytes="$(stat -f%z "$output" 2>/dev/null || printf '0')"
    if [[ "$win_rc" -eq 0 && "$win_bytes" -gt 0 ]]; then
      printf 'window_id:%s\n' "$wid"
      return 0
    fi
  fi
  # 主路径失败:判定并留痕锁屏态与分模式结果,再决定 fallback。
  # 注意 -R fallback 不是「抢救出图」——锁屏时 osascript 摆不了窗口,几何前提
  # 本就不成立,此时不存在“正确的画面”可抢救,只能如实报失败。
  lock_state="$(python3 "${LOCK_STATE_HELPER:-$REPO_ROOT/tools/visual_capture/lock_state.py}" 2>/dev/null || printf 'unknown')"
  if [[ -n "$log" ]]; then
    {
      printf 'VISUAL_CAPTURE_DIAG: lock_state=%s\n' "$lock_state"
      printf 'VISUAL_CAPTURE_DIAG: window_id=%s\n' "${wid:-<empty>}"
      if [[ -n "$wid" ]]; then
        printf 'VISUAL_CAPTURE_DIAG: window_capture_rc=%s bytes=%s\n' "$win_rc" "$win_bytes"
      fi
    } >>"$log"
  fi
  # 锁屏时区域 fallback 救不出正确画面:-R 本身锁屏必死(2026-08-12 audit 8 采样
  # 完美相关),即使侥幸出图也只是锁屏画面(窗口没被 osascript 摆到左上角)。
  # 看似成功的错图比明着失败更糟(本仓有过整张错拍事故)→ 跳 fallback 硬停。
  if [[ "$lock_state" == "locked" ]]; then
    printf 'all_failed:lock=locked\n'
    return 1
  fi
  capture_region "$width" "$height" "$output" || region_rc=$?
  if [[ "$region_rc" -eq 0 && -s "$output" ]]; then
    printf 'fallback_region\n'
    return 0
  fi
  printf 'all_failed:lock=%s\n' "$lock_state"
  return 1
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
  # TERM 免疫僵尸(READY 超时后 kill 未退的卡死进程)是批 C cycle 720 错拍与
  # 「首启抖动」的共同真身:pkill 后必须确认退净,不净升级 SIGKILL 再确认。
  pkill -x "$APP_PROCESS_NAME" >/dev/null 2>&1 || true
  elapsed=0
  while [[ "$elapsed" -lt 5 ]]; do
    if ! pgrep -x "$APP_PROCESS_NAME" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  pkill -9 -x "$APP_PROCESS_NAME" >/dev/null 2>&1 || true
  elapsed=0
  while [[ "$elapsed" -lt 5 ]]; do
    if ! pgrep -x "$APP_PROCESS_NAME" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done
  echo "VISUAL_CAPTURE_WARN: stale $APP_PROCESS_NAME still alive after SIGKILL" >&2
}

# 停掉本次启动的 app:SIGTERM → 5s 内未退升级 SIGKILL → wait 收尸。
# 裸杀+wait 对 TERM 免疫进程会让 wait 永挂 / 或留下僵尸窗口污染下一 route。
stop_pid() {
  local pid="$1"
  local log="$2"
  kill "$pid" >/dev/null 2>&1 || true
  local elapsed=0
  while kill -0 "$pid" >/dev/null 2>&1 && [[ "$elapsed" -lt 5 ]]; do
    sleep 1
    elapsed=$((elapsed + 1))
  done
  if kill -0 "$pid" >/dev/null 2>&1; then
    kill -9 "$pid" >/dev/null 2>&1 || true
    printf 'VISUAL_CAPTURE_WARN: app pid %s ignored SIGTERM, escalated to SIGKILL\n' "$pid" >>"$log"
  fi
  wait "$pid" >/dev/null 2>&1 || true
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
