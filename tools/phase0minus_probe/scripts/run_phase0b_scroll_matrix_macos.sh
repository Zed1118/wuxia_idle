#!/usr/bin/env bash
set -euo pipefail

probe_dir="$(cd "$(dirname "$0")/.." && pwd)"
duration_scale="${1:-1.0}"
window_x="${2:-}"
window_y="${3:-}"
matrix_id="phase0b-scroll-matrix-$(date -u +%Y%m%dT%H%M%SZ)"
matrix_started="$(date +%s)"

repository_root="$(cd "$probe_dir/../.." && pwd)"
build_commit="$(git -C "$repository_root" rev-parse HEAD)"
panorama_sha256="$(shasum -a 256 "$probe_dir/assets/phase0b/runtime/scroll_panorama_mountain_to_gate_v1.png" | awk '{print $1}')"
cd "$probe_dir"
flutter build macos --profile \
  --dart-define=PROBE_BUILD_COMMIT="$build_commit" \
  --dart-define=PHASE0B_PANORAMA_SHA256="$panorama_sha256"
for viewport in desktop_1280x720 desktop_1440x900; do
  PROBE_SKIP_BUILD=true \
    "$probe_dir/scripts/run_phase0b_scroll_macos.sh" \
    "$viewport" 3 "$duration_scale" "$window_x" "$window_y"
done

/usr/bin/python3 - "$probe_dir/build/results/phase0b-scroll" "$matrix_started" "$matrix_id" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
started = int(sys.argv[2])
matrix_id = sys.argv[3]
paths = sorted(
    (path for path in root.glob('*/summary.json') if path.stat().st_mtime >= started),
    key=lambda path: path.stat().st_mtime,
)
if len(paths) != 6:
    raise SystemExit(f'PHASE0B_SCROLL_MATRIX_INVALID expected 6 fresh summaries, got {len(paths)}')
keys = (
    'run_id', 'build_commit', 'panorama_sha256', 'viewport', 'frames', 'total_span',
    'over_reference_budget_count', 'maximum_severe_streak',
    'rss_warmup_end_bytes', 'rss_peak_bytes', 'rss_cooldown_end_bytes', 'workload',
)
observations = []
for path in paths:
    with path.open(encoding='utf-8') as source:
        item = json.load(source)
    observations.append({key: item[key] for key in keys})
report = {
    'schema_version': 1,
    'matrix_id': matrix_id,
    'gate_eligible': False,
    'claim': 'continuous_map_camera_and_local_art_load_observation_only',
    'observations': observations,
}
with (root / f'{matrix_id}.json').open('w', encoding='utf-8') as target:
    json.dump(report, target, ensure_ascii=False, indent=2)
    target.write('\n')
PY
echo "PHASE0B_SCROLL_MATRIX_OBSERVED $matrix_id"
