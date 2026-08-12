#!/usr/bin/env bash
set -euo pipefail

probe_dir="$(cd "$(dirname "$0")/.." && pwd)"
repository_root="$(cd "$probe_dir/../.." && pwd)"
viewport="${1:-desktop_1280x720}"
tier="${2:-stress_30}"
repeat="${3:-1}"
duration_scale="${4:-1.0}"

case "$viewport" in
  desktop_1280x720|desktop_1440x900) ;;
  *) echo "Unsupported viewport: $viewport" >&2; exit 2 ;;
esac
case "$tier" in
  baseline_10|target_20_plus_1|stress_30) ;;
  *) echo "Unsupported tier: $tier" >&2; exit 2 ;;
esac

cd "$probe_dir"
for ((index = 1; index <= repeat; index++)); do
  run_id="macos-${viewport}-${tier}-r${index}-$(date -u +%Y%m%dT%H%M%SZ)"
  flutter run -d macos --profile \
    --dart-define="PROBE_VIEWPORT=$viewport" \
    --dart-define="PROBE_TIER=$tier" \
    --dart-define="PROBE_RUN_ID=$run_id" \
    --dart-define="PROBE_DURATION_SCALE=$duration_scale" \
    --dart-define="PROBE_OUTPUT_ROOT=$probe_dir/build/results" \
    --dart-define="PROBE_REPOSITORY_ROOT=$repository_root" \
    --dart-define=PROBE_AUTO_CLOSE=true
done
