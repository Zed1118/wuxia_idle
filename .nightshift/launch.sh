#!/bin/bash
# Nightshift launcher · 启动后台 dispatcher,脱离当前 shell
# Usage:
#   bash .nightshift/launch.sh
#   (或直接 `./launch.sh` 在 .nightshift 目录内)

set -e

DISPATCHER="/Users/a10506/Desktop/挂机武侠/.nightshift/dispatcher.sh"
LAUNCH_LOG="/Users/a10506/Desktop/挂机武侠/.nightshift/logs/launcher.log"

mkdir -p "$(dirname "$LAUNCH_LOG")"

# Check if already running
if pgrep -f "nightshift/dispatcher.sh" > /dev/null; then
  echo "WARN: dispatcher already running"
  pgrep -fl "nightshift/dispatcher.sh"
  echo "To kill: pkill -f nightshift/dispatcher.sh"
  exit 1
fi

# Launch detached: nohup + caffeinate + redirect everything + & + disown
nohup caffeinate -dimsu bash "$DISPATCHER" \
  < /dev/null \
  > "$LAUNCH_LOG" 2>&1 \
  &
DISPATCHER_PID=$!
disown $DISPATCHER_PID 2>/dev/null || true

# Wait a beat to confirm process actually spawned
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
echo "  Status: /Users/a10506/Desktop/挂机武侠/.nightshift/status/"
echo "  Task logs: /Users/a10506/Desktop/挂机武侠/.nightshift/logs/T0X.log"
echo "========================================="
echo "Monitor (live):"
echo "  tail -f /Users/a10506/Desktop/挂机武侠/.nightshift/logs/dispatcher.log"
echo "Cancel:"
echo "  kill $DISPATCHER_PID"
echo "  # or"
echo "  pkill -f nightshift/dispatcher.sh"
echo "========================================="
echo "Estimated finish: ~2-3h actual (8h budget per user-sleep window)"
echo "========================================="
