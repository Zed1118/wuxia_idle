#!/usr/bin/env bash
set -euo pipefail

probe_dir="$(cd "$(dirname "$0")/.." && pwd)"
viewport="${1:-desktop_1280x720}"
repeat="${2:-1}"
duration_scale="${3:-1.0}"
window_x="${4:-}"
window_y="${5:-}"
if [[ -z "${PROBE_EXPECTED_REFRESH_RATE:-}" ]]; then
  echo "PROBE_EXPECTED_REFRESH_RATE must be set (e.g. 60 or 144)." >&2
  exit 2
fi
if [[ -z "${PROBE_EXPECTED_DPR:-}" ]]; then
  echo "PROBE_EXPECTED_DPR must be set (e.g. 1 or 2)." >&2
  exit 2
fi
expected_refresh="$PROBE_EXPECTED_REFRESH_RATE"
expected_dpr="$PROBE_EXPECTED_DPR"

case "$viewport" in
  desktop_1280x720) expected_width=1280; expected_height=720 ;;
  desktop_1440x900) expected_width=1440; expected_height=900 ;;
  *) echo "Unsupported viewport: $viewport" >&2; exit 2 ;;
esac

repository_root="$(cd "$probe_dir/../.." && pwd)"
build_commit="$(git -C "$repository_root" rev-parse HEAD)"
background_sha256="$(shasum -a 256 "$probe_dir/assets/phase0b/runtime/mountain_pass_background_v2.png" | awk '{print $1}')"
founder_sha256="$(shasum -a 256 "$probe_dir/assets/phase0b/runtime/founder_pose_atlas_v1.png" | awk '{print $1}')"
bandit_sha256="$(shasum -a 256 "$probe_dir/assets/phase0b/runtime/bandit_pose_atlas_v1.png" | awk '{print $1}')"
elite_sha256="$(shasum -a 256 "$probe_dir/assets/phase0b/runtime/elite_pose_atlas_v1.png" | awk '{print $1}')"

cd "$probe_dir"
if [[ "${PROBE_SKIP_BUILD:-false}" != "true" ]]; then
  flutter build macos --profile \
    --dart-define=PROBE_BUILD_COMMIT="$build_commit" \
    --dart-define=PHASE0B_ARTLOAD_BG_SHA256="$background_sha256" \
    --dart-define=PHASE0B_ARTLOAD_FOUNDER_SHA256="$founder_sha256" \
    --dart-define=PHASE0B_ARTLOAD_BANDIT_SHA256="$bandit_sha256" \
    --dart-define=PHASE0B_ARTLOAD_ELITE_SHA256="$elite_sha256"
fi
binary="$probe_dir/build/macos/Build/Products/Profile/phase0minus_probe.app/Contents/MacOS/phase0minus_probe"
if [[ ! -x "$binary" ]]; then
  echo "Profile binary not found: $binary" >&2
  exit 3
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to validate Phase 0B observations." >&2
  exit 4
fi

for ((index = 1; index <= repeat; index++)); do
  run_id="phase0b-art-load-macos-${viewport}-r${index}-$(date -u +%Y%m%dT%H%M%SZ)"
  run_env=(env \
    PROBE_MODE=phase0b_art_load \
    PROBE_VIEWPORT="$viewport" \
    PROBE_RUN_ID="$run_id" \
    PROBE_DURATION_SCALE="$duration_scale" \
    PROBE_OUTPUT_ROOT="$probe_dir/build/results" \
    PROBE_AUTO_CLOSE=true)
  if [[ -n "$window_x" && -n "$window_y" ]]; then
    run_env+=(PROBE_WINDOW_X="$window_x" PROBE_WINDOW_Y="$window_y")
  fi
  "${run_env[@]}" caffeinate -dimsu "$binary"

  summary="$probe_dir/build/results/phase0b-art-load/$run_id/summary.json"
  if [[ ! -f "$summary" ]]; then
    echo "PHASE0B_ART_LOAD_INVALID missing summary for $run_id" >&2
    exit 5
  fi
  jq -e \
    --arg viewport "$viewport" \
    --argjson expected_width "$expected_width" \
    --argjson expected_height "$expected_height" \
    --argjson expected_refresh "$expected_refresh" \
    --argjson expected_dpr "$expected_dpr" \
    --arg build_commit "$build_commit" \
    --arg background_sha256 "$background_sha256" \
    --arg founder_sha256 "$founder_sha256" \
    --arg bandit_sha256 "$bandit_sha256" \
    --arg elite_sha256 "$elite_sha256" \
    '.probe_kind == "phase0b_art_load" and
     .gate_eligible == false and
     .claim == "art_load_observation_only_not_phase0minus_or_gameplay_gate" and
     .build_mode == "profile" and
     .build_commit == $build_commit and
     .asset_sha256.background == $background_sha256 and
     .asset_sha256.founder == $founder_sha256 and
     .asset_sha256.bandit == $bandit_sha256 and
     .asset_sha256.elite == $elite_sha256 and
     .validity == "VALID_OBSERVATION" and
     .entity_counts == {"hero":1,"ordinary":20,"elite":1} and
     .logical_image_rect_ops == 23 and
     .viewport.id == $viewport and
     .viewport.actual_width == $expected_width and
     .viewport.actual_height == $expected_height and
     .viewport.refresh_rate_hz == $expected_refresh and
     .viewport.device_pixel_ratio == $expected_dpr and
     (.total_span.p99_us | type == "number")' \
    "$summary" >/dev/null || {
      echo "PHASE0B_ART_LOAD_INVALID malformed observation for $run_id" >&2
      exit 6
    }
  echo "PHASE0B_ART_LOAD_OBSERVATION_VALID $run_id"
done
