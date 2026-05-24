#!/bin/bash
# Nightshift launcher · 通用模板 v2
# 启动后台 dispatcher,脱离当前 shell

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISPATCHER="$SCRIPT_DIR/dispatcher.sh"
LAUNCH_LOG="$SCRIPT_DIR/logs/launcher.log"

mkdir -p "$(dirname "$LAUNCH_LOG")"

if pgrep -f "$DISPATCHER" > /dev/null; then
  echo "WARN: dispatcher already running"
  pgrep -fl "$DISPATCHER"
  echo "To kill: pkill -f \"$DISPATCHER\""
  exit 1
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
