#!/usr/bin/env bash
set -euo pipefail

ROUTE="${1:-battle_v2_neutral_3v3}"
SECONDS_TO_SAMPLE="${BATTLE_PROFILE_SECONDS:-60}"
OUTPUT_DIR="${BATTLE_PROFILE_OUTPUT_DIR:-build/visual_acceptance/battle_ui_v2_85/stage3_profile}"
LOG="$OUTPUT_DIR/$ROUTE-profile.log"
SUMMARY="$OUTPUT_DIR/$ROUTE-profile.json"

mkdir -p "$OUTPUT_DIR"

flutter run -d macos --profile \
  --dart-define=VISUAL_ROUTE="$ROUTE" \
  --dart-define=BATTLE_FRAME_PROFILE_SECONDS="$SECONDS_TO_SAMPLE" \
  >"$LOG" 2>&1 < /dev/null &
flutter_pid=$!

cleanup() {
  kill "$flutter_pid" >/dev/null 2>&1 || true
  wait "$flutter_pid" >/dev/null 2>&1 || true
}
trap cleanup EXIT

deadline=$((SECONDS + SECONDS_TO_SAMPLE + 180))
while (( SECONDS < deadline )); do
  if grep -q 'BATTLE_FRAME_PROFILE_SUMMARY:' "$LOG" 2>/dev/null; then
    sed -n 's/^.*BATTLE_FRAME_PROFILE_SUMMARY: //p' "$LOG" | tail -1 >"$SUMMARY"
    python3 -m json.tool "$SUMMARY" >/dev/null
    printf 'BATTLE_FRAME_PROFILE_ARTIFACT: %s\n' "$SUMMARY"
    exit 0
  fi
  if grep -q 'VISUAL_ROUTE_ERROR:' "$LOG" 2>/dev/null; then
    printf 'Profile route failed; see %s\n' "$LOG" >&2
    exit 1
  fi
  sleep 1
done

printf 'Timed out waiting for profile summary; see %s\n' "$LOG" >&2
exit 1
