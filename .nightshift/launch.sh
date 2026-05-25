#!/bin/bash
# Nightshift launcher · 通用模板 v2
# 启动后台 dispatcher,脱离当前 shell

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISPATCHER="$SCRIPT_DIR/dispatcher.sh"
LAUNCH_LOG="$SCRIPT_DIR/logs/launcher.log"
CONF="$SCRIPT_DIR/nightshift.conf"

mkdir -p "$(dirname "$LAUNCH_LOG")"

if pgrep -f "$DISPATCHER" > /dev/null; then
  echo "WARN: dispatcher already running"
  pgrep -fl "$DISPATCHER"
  echo "To kill: pkill -f \"$DISPATCHER\""
  exit 1
fi

# === B1 容量预报(memory feedback-nightshift-v2-first-run-lessons B1) ===
# launch 前算 sum(ESTIMATED_MIN_<task>) / PLAN_WINDOW_MIN 饱满度
# conf 可设:
#   ESTIMATED_MIN_PER_TASK=15      (默认每 task 估时)
#   ESTIMATED_MIN_T17b=30          (per-task override)
#   PLAN_WINDOW_MIN=180            (规划窗口,默认 180min=3h)
if [ -f "$CONF" ]; then
  # shellcheck disable=SC1090
  source "$CONF"
  if [ -n "${TASKS+x}" ] && [ "${#TASKS[@]}" -gt 0 ]; then
    total_est_min=0
    for t in "${TASKS[@]}"; do
      est_var="ESTIMATED_MIN_${t}"
      est="${!est_var:-${ESTIMATED_MIN_PER_TASK:-15}}"
      total_est_min=$((total_est_min + est))
    done
    window_min="${PLAN_WINDOW_MIN:-180}"
    fill_pct=$((total_est_min * 100 / window_min))
    echo "==========================================="
    echo "容量预报: ${#TASKS[@]} task · 估时 ${total_est_min}min / 窗口 ${window_min}min = ${fill_pct}%"
    if [ "$fill_pct" -lt 50 ]; then
      echo "  ⚠ 饱满度 < 50%,可加 task(opus --print doc/spec 类 ×0.15-0.20)"
    elif [ "$fill_pct" -gt 110 ]; then
      echo "  ⚠ 饱满度 > 110%,可能超时(单 task TIMEOUT=${TASK_TIMEOUT_MIN:-75}min)"
    else
      echo "  饱满度 50-110% 合理"
    fi
    echo "  预算: ${#TASKS[@]} × \$${TASK_BUDGET_USD:-8} = \$$(( ${#TASKS[@]} * ${TASK_BUDGET_USD:-8} ))"
    echo "==========================================="
  fi
fi

# 脱离 shell: nohup + caffeinate + disown
nohup caffeinate -dimsu bash "$DISPATCHER" \
  < /dev/null \
  > "$LAUNCH_LOG" 2>&1 \
  &
DISPATCHER_PID=$!
disown $DISPATCHER_PID 2>/dev/null || true

sleep 1
if ! kill -0 $DISPATCHER_PID 2>/dev/null; then
  echo "FAIL: dispatcher PID $DISPATCHER_PID did not survive 1s"
  echo "Check log: $LAUNCH_LOG"
  exit 2
fi

echo "========================================="
echo "Nightshift dispatcher launched"
echo "  PID:    $DISPATCHER_PID"
echo "  Log:    $LAUNCH_LOG"
echo "  Status: $SCRIPT_DIR/status/"
echo "  Tasks:  $SCRIPT_DIR/logs/T0X.log"
echo "========================================="
echo "Monitor (live):"
echo "  tail -f $SCRIPT_DIR/logs/dispatcher.log"
echo "Cancel:"
echo "  kill $DISPATCHER_PID"
echo "  # or: pkill -f \"$DISPATCHER\""
echo "Morning report (auto-runs at finish, or manual):"
echo "  bash $SCRIPT_DIR/morning.sh"
echo "========================================="
