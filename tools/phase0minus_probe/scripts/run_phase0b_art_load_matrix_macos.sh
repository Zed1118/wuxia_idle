#!/usr/bin/env bash
set -euo pipefail

probe_dir="$(cd "$(dirname "$0")/.." && pwd)"
duration_scale="${1:-1.0}"
window_x="${2:-}"
window_y="${3:-}"
matrix_id="phase0b-art-load-matrix-$(date -u +%Y%m%dT%H%M%SZ)"
matrix_started="$(date +%s)"

cd "$probe_dir"
flutter build macos --profile
for viewport in desktop_1280x720 desktop_1440x900; do
  PROBE_SKIP_BUILD=true \
    "$probe_dir/scripts/run_phase0b_art_load_macos.sh" \
    "$viewport" 3 "$duration_scale" "$window_x" "$window_y"
done

/usr/bin/python3 - \
  "$probe_dir/build/results/phase0b-art-load" \
  "$matrix_started" "$matrix_id" <<'PY'
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
    raise SystemExit(
        f'PHASE0B_ART_LOAD_MATRIX_INVALID expected 6 fresh summaries, got {len(paths)}'
    )
keys = (
    'run_id', 'viewport', 'frames', 'total_span', 'build_duration',
    'raster_duration', 'over_reference_budget_count', 'maximum_severe_streak',
    'rss_warmup_end_bytes', 'rss_peak_bytes', 'rss_cooldown_end_bytes',
    'decoded_texture_bytes_theoretical',
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
    'claim': 'art_load_observation_only_not_phase0minus_or_gameplay_gate',
    'observations': observations,
}
with (root / f'{matrix_id}.json').open('w', encoding='utf-8') as target:
    json.dump(report, target, ensure_ascii=False, indent=2)
    target.write('\n')
PY
echo "PHASE0B_ART_LOAD_MATRIX_OBSERVED $matrix_id"
