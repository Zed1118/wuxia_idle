#!/usr/bin/env bash
set -euo pipefail

probe_dir="$(cd "$(dirname "$0")/.." && pwd)"
duration_scale="${1:-1.0}"
window_x="${2:-}"
window_y="${3:-}"
matrix_id="phase0b-art-load-matrix-$(date -u +%Y%m%dT%H%M%SZ)"
matrix_started="$(date +%s)"

repository_root="$(cd "$probe_dir/../.." && pwd)"
build_commit="$(git -C "$repository_root" rev-parse HEAD)"
background_sha256="$(shasum -a 256 "$probe_dir/assets/phase0b/runtime/mountain_pass_background_v2.png" | awk '{print $1}')"
founder_sha256="$(shasum -a 256 "$probe_dir/assets/phase0b/runtime/founder_pose_atlas_v1.png" | awk '{print $1}')"
bandit_sha256="$(shasum -a 256 "$probe_dir/assets/phase0b/runtime/bandit_pose_atlas_v1.png" | awk '{print $1}')"
elite_sha256="$(shasum -a 256 "$probe_dir/assets/phase0b/runtime/elite_pose_atlas_v1.png" | awk '{print $1}')"

cd "$probe_dir"
flutter build macos --profile \
  --dart-define=PROBE_BUILD_COMMIT="$build_commit" \
  --dart-define=PHASE0B_ARTLOAD_BG_SHA256="$background_sha256" \
  --dart-define=PHASE0B_ARTLOAD_FOUNDER_SHA256="$founder_sha256" \
  --dart-define=PHASE0B_ARTLOAD_BANDIT_SHA256="$bandit_sha256" \
  --dart-define=PHASE0B_ARTLOAD_ELITE_SHA256="$elite_sha256"
for viewport in desktop_1280x720 desktop_1440x900; do
  PROBE_SKIP_BUILD=true \
    "$probe_dir/scripts/run_phase0b_art_load_macos.sh" \
    "$viewport" 3 "$duration_scale" "$window_x" "$window_y"
done

/usr/bin/python3 - \
  "$probe_dir/build/results/phase0b-art-load" \
  "$matrix_started" \
  "$matrix_id" \
  "$build_commit" \
  "$background_sha256" \
  "$founder_sha256" \
  "$bandit_sha256" \
  "$elite_sha256" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
started = int(sys.argv[2])
matrix_id = sys.argv[3]
build_commit = sys.argv[4]
background_sha256 = sys.argv[5]
founder_sha256 = sys.argv[6]
bandit_sha256 = sys.argv[7]
elite_sha256 = sys.argv[8]
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
    'build_commit': build_commit,
    'asset_sha256': {
        'background': background_sha256,
        'founder': founder_sha256,
        'bandit': bandit_sha256,
        'elite': elite_sha256,
    },
    'observations': observations,
}
with (root / f'{matrix_id}.json').open('w', encoding='utf-8') as target:
    json.dump(report, target, ensure_ascii=False, indent=2)
    target.write('\n')
PY
echo "PHASE0B_ART_LOAD_MATRIX_OBSERVED $matrix_id"
