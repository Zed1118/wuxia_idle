#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repeat="${1:-3}"
duration_scale="${2:-1.0}"
window_x="${3:-}"
window_y="${4:-}"
probe_dir="$(cd "$script_dir/.." && pwd)"

cd "$probe_dir"
flutter build macos --profile

for viewport in desktop_1280x720 desktop_1440x900; do
  for tier in baseline_10 target_20_plus_1 stress_30; do
    PROBE_SKIP_BUILD=true "$script_dir/run_macos_profile.sh" \
      "$viewport" "$tier" "$repeat" "$duration_scale" "$window_x" "$window_y"
  done
done
