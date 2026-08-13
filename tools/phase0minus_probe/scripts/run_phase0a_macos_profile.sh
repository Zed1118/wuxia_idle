#!/usr/bin/env bash
set -euo pipefail

probe_dir="$(cd "$(dirname "$0")/.." && pwd)"
repository_root="$(cd "$probe_dir/../.." && pwd)"
viewport="${1:-desktop_1280x720}"
repeat="${2:-1}"
duration_scale="${3:-1.0}"
expected_dpr="${PROBE_GATE_DPR:-1}"
window_x="${4:-}"
window_y="${5:-}"

case "$viewport" in
  desktop_1280x720|desktop_1440x900) ;;
  *) echo "Unsupported viewport: $viewport" >&2; exit 2 ;;
esac

cd "$probe_dir"
if [[ "${PROBE_SKIP_BUILD:-false}" != "true" ]]; then
  flutter build macos --profile
fi
binary="$probe_dir/build/macos/Build/Products/Profile/phase0minus_probe.app/Contents/MacOS/phase0minus_probe"
if [[ ! -x "$binary" ]]; then
  echo "Profile binary not found: $binary" >&2
  exit 3
fi

for ((index = 1; index <= repeat; index++)); do
  run_id="phase0a-replay-macos-${viewport}-r${index}-$(date -u +%Y%m%dT%H%M%SZ)"
  run_env=(env \
    PROBE_MODE=phase0a_replay \
    PROBE_VIEWPORT="$viewport" \
    PROBE_RUN_ID="$run_id" \
    PROBE_DURATION_SCALE="$duration_scale" \
    PROBE_OUTPUT_ROOT="$probe_dir/build/results" \
    PROBE_REPOSITORY_ROOT="$repository_root" \
    PROBE_AUTO_CLOSE=true \
    PROBE_EXPECTED_REFRESH_RATE=60 \
    PROBE_EXPECTED_DPR="$expected_dpr")
  if [[ -n "$window_x" && -n "$window_y" ]]; then
    run_env+=(PROBE_WINDOW_X="$window_x" PROBE_WINDOW_Y="$window_y")
  fi
  "${run_env[@]}" "$binary"
done
