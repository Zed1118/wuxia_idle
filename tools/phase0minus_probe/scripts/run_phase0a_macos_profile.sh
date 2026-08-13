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
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to validate each macOS result." >&2
  exit 4
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
  # The app focuses its own exact window. caffeinate keeps the local display
  # session active without launching a second copy of the app.
  "${run_env[@]}" caffeinate -dimsu "$binary"
  summary="$probe_dir/build/results/phase0a-replays/$run_id/summary.json"
  manifest="$probe_dir/build/results/phase0a-replays/$run_id/manifest.json"
  if [[ ! -f "$summary" || ! -f "$manifest" ]]; then
    echo "PHASE0A_MACOS_RUN_FAIL missing result for $run_id" >&2
    exit 5
  fi
  expected_commit=$(git -C "$repository_root" rev-parse HEAD)
  jq -e \
    --arg viewport "$viewport" \
    --arg commit "$expected_commit" \
    --argjson dpr "$expected_dpr" \
    '.viewport == $viewport and
     .frame_metrics.validity == "VALID" and
     .frame_metrics.gate == "PASS" and
     .workload.mode == "phase0a_replay" and
     .workload.gate_eligible_duration == true and
     .workload.gate_breakdown.timing_gc_gate == "PASS" and
     .workload.gate_breakdown.resident_pool_gate == "PASS" and
     .workload.gate_breakdown.workload_coverage_gate == "PASS" and
     .workload.gate_breakdown.rss_gate == "PASS" and
     .workload.gate_breakdown.collision_workload_gate == "PASS"' \
    "$summary" >/dev/null || {
      echo "PHASE0A_MACOS_RUN_FAIL invalid summary for $run_id" >&2
      exit 6
    }
  jq -e \
    --arg viewport "$viewport" \
    --arg commit "$expected_commit" \
    --argjson dpr "$expected_dpr" \
    '.viewport.id == $viewport and
     .git_commit == $commit and
     .git_dirty == false and
     .flutter_build_mode == "profile" and
     .device_pixel_ratio == $dpr and
     .refresh_rate_hz == 60' \
    "$manifest" >/dev/null || {
      echo "PHASE0A_MACOS_RUN_FAIL invalid manifest for $run_id" >&2
      exit 7
    }
  echo "PHASE0A_MACOS_RUN_PASS $run_id"
done
