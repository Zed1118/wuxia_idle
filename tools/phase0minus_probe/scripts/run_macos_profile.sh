#!/usr/bin/env bash
set -euo pipefail

probe_dir="$(cd "$(dirname "$0")/.." && pwd)"
repository_root="$(cd "$probe_dir/../.." && pwd)"
viewport="${1:-desktop_1280x720}"
tier="${2:-stress_30}"
repeat="${3:-1}"
duration_scale="${4:-1.0}"
window_x="${5:-}"
window_y="${6:-}"
expected_dpr="${PROBE_GATE_DPR:-1}"

case "$viewport" in
  desktop_1280x720|desktop_1440x900) ;;
  *) echo "Unsupported viewport: $viewport" >&2; exit 2 ;;
esac
case "$tier" in
  baseline_10|target_20_plus_1|stress_30) ;;
  *) echo "Unsupported tier: $tier" >&2; exit 2 ;;
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
  run_id="macos-${viewport}-${tier}-r${index}-$(date -u +%Y%m%dT%H%M%SZ)"
  run_env=(
    env
    "PROBE_VIEWPORT=$viewport"
    "PROBE_TIER=$tier"
    "PROBE_RUN_ID=$run_id"
    "PROBE_DURATION_SCALE=$duration_scale"
    "PROBE_OUTPUT_ROOT=$probe_dir/build/results"
    "PROBE_REPOSITORY_ROOT=$repository_root"
    "PROBE_AUTO_CLOSE=true"
    "PROBE_EXPECTED_REFRESH_RATE=60"
    "PROBE_EXPECTED_DPR=$expected_dpr"
  )
  if [[ -n "$window_x" && -n "$window_y" ]]; then
    run_env+=(
      "PROBE_WINDOW_X=$window_x"
      "PROBE_WINDOW_Y=$window_y"
    )
  fi
  "${run_env[@]}" "$binary"
  manifest="$probe_dir/build/results/$run_id/manifest.json"
  if ! /usr/bin/python3 - "$manifest" "$expected_dpr" <<'PY'
import json
import sys

with open(sys.argv[1], encoding='utf-8') as source:
    manifest = json.load(source)
viewport = manifest['viewport']
valid = abs(float(viewport['refresh_rate_hz']) - 60.0) < 0.5
valid = valid and abs(float(viewport['device_pixel_ratio']) - float(sys.argv[2])) < 0.01
raise SystemExit(0 if valid else 4)
PY
  then
    echo "Run $run_id landed on the wrong display; stopping matrix." >&2
    exit 4
  fi
done
