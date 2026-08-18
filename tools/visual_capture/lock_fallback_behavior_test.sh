#!/usr/bin/env bash
# capture_visual_window 锁屏 fallback 行为测(2026-08-18,BACKLOG 二#11)。
#
# 方法:PATH 注 stub(screencapture/swift/python3/osascript),锁屏态经 lock_state.py
# 的 --ioreg-file 注入,无需真锁屏即可钉死分支行为。
#
# 钉的行为(根因 2026-08-12 audit 定谳:锁屏时 -R 必死、窗口截图照常成功):
#   case 1 未锁 + 窗口失败 + 区域成功 => fallback_region,rc=0(有效兜底不破)
#   case 2 窗口成功 => window_id:<wid>,rc=0(快路径不查锁)
#   case 3 锁屏 + 窗口失败 => 跳区域 fallback,all_failed:lock=locked,rc!=0
#          (区域 -R 锁屏必死,即使出图也是锁屏画面=错内容;明着失败优于假成功)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"

WORK="$(mktemp -d /tmp/vc_lock_test.XXXXXX)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

STUB_DIR="$WORK/stubs"
mkdir -p "$STUB_DIR"

# screencapture stub:-l<窗口> 模式读 VC_STUB_WIN_RC(缺省 0),成功写出非空 png;
# -R<区域> 模式读 VC_STUB_REGION_RC(缺省 0),成功写出非空 png。
cat >"$STUB_DIR/screencapture" <<'STUB'
#!/usr/bin/env bash
mode=""
out=""
for arg in "$@"; do
  case "$arg" in
    -l*) mode="window" ;;
    -R*) mode="region" ;;
    -x|-o) ;;
    *) out="$arg" ;;
  esac
done
if [[ "$mode" == "window" ]]; then
  rc="${VC_STUB_WIN_RC:-0}"
else
  rc="${VC_STUB_REGION_RC:-0}"
fi
if [[ "$rc" -eq 0 && -n "$out" ]]; then
  printf 'FAKEPNG\n' >"$out"
fi
exit "$rc"
STUB

# swift stub:stderr 打 BEST=<wid>(window_id() 从 stderr 解析)。
cat >"$STUB_DIR/swift" <<'STUB'
#!/usr/bin/env bash
echo "BEST=${VC_STUB_WID:-424242}" >&2
exit 0
STUB

# python3 stub:lock_state.py 转发真实 python3(锁屏态经 --ioreg-file 注入),
# 其余 python 调用一律空跑成功。
cat >"$STUB_DIR/python3" <<STUB
#!/usr/bin/env bash
case "\${1:-}" in
  *lock_state.py) exec /usr/bin/python3 "\$@" ;;
  *) exit 0 ;;
esac
STUB

cat >"$STUB_DIR/osascript" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod +x "$STUB_DIR"/*

LOCKED_IOREG="$WORK/ioreg_locked.txt"
UNLOCKED_IOREG="$WORK/ioreg_unlocked.txt"
printf '+-o Root\n  "IOConsoleUsers" = ({"CGSSessionScreenIsLocked"=1})\n' >"$LOCKED_IOREG"
printf '+-o Root\n  "IOConsoleUsers" = ({"kCGSSessionUserIDKey"=501})\n' >"$UNLOCKED_IOREG"

PATH="$STUB_DIR:$PATH"
APP_PROCESS_NAME="wuxia_idle"
SWIFT_WINID="$HERE/window_id.swift"
LOCK_STATE_HELPER="$HERE/lock_state.py"
ALL_SPACES=0
export VC_TEST_LOCK_IOREG_FILE

source "$HERE/visual_capture_lib.sh"

fail_count=0
check() {
  local name="$1"
  local ok="$2"
  local detail="$3"
  if [[ "$ok" -eq 1 ]]; then
    printf 'PASS %s\n' "$name"
  else
    printf 'FAIL %s: %s\n' "$name" "$detail"
    fail_count=$((fail_count + 1))
  fi
}

run_case() {
  # 重置每 case 环境;capture_visual_window 在子壳里跑,捕获状态串与 rc。
  CASE_OUT="$WORK/$1.png"
  CASE_LOG="$WORK/$1.log"
  rm -f "$CASE_OUT" "$CASE_LOG"
  CASE_STATUS=""
  CASE_RC=0
  CASE_STATUS="$(capture_visual_window 1280 720 "$CASE_OUT" "" "$CASE_LOG")" || CASE_RC=$?
}

# case 1:未锁 + 窗口截图失败 + 区域成功 => fallback_region
export VC_STUB_WIN_RC=3
export VC_STUB_REGION_RC=0
export VC_TEST_LOCK_IOREG_FILE="$UNLOCKED_IOREG"
run_case unlocked_region_fallback
if [[ "$CASE_RC" -eq 0 && "$CASE_STATUS" == "fallback_region" && -s "$CASE_OUT" ]] \
  && grep -q 'VISUAL_CAPTURE_DIAG: lock_state=unlocked' "$CASE_LOG"; then
  check unlocked_region_fallback 1 ""
else
  check unlocked_region_fallback 0 "rc=$CASE_RC status=$CASE_STATUS"
fi

# case 2:窗口截图成功 => 快路径,不查锁
export VC_STUB_WIN_RC=0
export VC_TEST_LOCK_IOREG_FILE="$LOCKED_IOREG"
run_case window_success
if [[ "$CASE_RC" -eq 0 && "$CASE_STATUS" == "window_id:424242" && -s "$CASE_OUT" ]]; then
  check window_success 1 ""
else
  check window_success 0 "rc=$CASE_RC status=$CASE_STATUS"
fi

# case 3:锁屏 + 窗口失败 => 跳区域 fallback,硬停
export VC_STUB_WIN_RC=3
export VC_STUB_REGION_RC=0
export VC_TEST_LOCK_IOREG_FILE="$LOCKED_IOREG"
run_case locked_skip_region
if [[ "$CASE_RC" -ne 0 && "$CASE_STATUS" == "all_failed:lock=locked" ]] \
  && grep -q 'VISUAL_CAPTURE_DIAG: lock_state=locked' "$CASE_LOG" \
  && [[ ! -s "$CASE_OUT" ]]; then
  check locked_skip_region 1 ""
else
  check locked_skip_region 0 "rc=$CASE_RC status=$CASE_STATUS"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf '%s case(s) failed\n' "$fail_count" >&2
  exit 1
fi
printf 'all lock fallback behavior cases passed\n'
