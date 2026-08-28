#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNNER="$REPO_ROOT/tools/playtest/playtest_capture.sh"
SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/playtest_capture_test.XXXXXX")"

cleanup() {
  find "$SCRATCH" -type f -delete 2>/dev/null || true
  find "$SCRATCH" -depth -type d -empty -delete 2>/dev/null || true
}
trap cleanup EXIT

BACKUP="$SCRATCH/backup"
mkdir "$BACKUP"
for slot in 1 2 3; do
  printf 'slot-%s\n' "$slot" >"$BACKUP/wuxia_save_slot${slot}.isar"
done
SCENARIO="$SCRATCH/scenario.json"
cat >"$SCENARIO" <<'JSON'
{
  "schema_version": 1,
  "id": "shell_dry_run",
  "production_entry": true,
  "recording_max_seconds": 30,
  "actions": [{"id": "wait", "type": "wait", "duration_ms": 1}]
}
JSON

OUTPUT="$SCRATCH/output"
DRY_LOG="$SCRATCH/dry.log"
bash "$RUNNER" \
  --scenario "$SCENARIO" \
  --output "$OUTPUT" \
  --save-backup "$BACKUP" \
  --app "$SCRATCH/fake.app/Contents/MacOS/wuxia_idle" \
  --dry-run >"$DRY_LOG"

grep -q 'scenario=shell_dry_run production_entry=true actions=CGEvent' "$DRY_LOG"
grep -q 'record=screencapture window-id' "$DRY_LOG"
grep -q 'keyframes=entry,first_contact,skill_release,settlement' "$DRY_LOG"
grep -q 'save_guard=three-slot fail-closed restore-and-cmp' "$DRY_LOG"
if [[ -e "$OUTPUT" ]]; then
  echo "dry-run unexpectedly created output" >&2
  exit 1
fi

DEGENERATE="$SCRATCH/degenerate.json"
sed 's/"production_entry": true/"production_entry": false/' "$SCENARIO" >"$DEGENERATE"
if bash "$RUNNER" \
  --scenario "$DEGENERATE" \
  --output "$OUTPUT" \
  --save-backup "$BACKUP" \
  --dry-run >"$SCRATCH/degenerate.log" 2>&1; then
  echo "degenerate production_entry unexpectedly passed" >&2
  exit 1
fi
grep -q 'scenario production_entry must be true' "$SCRATCH/degenerate.log"

grep -q 'trap on_exit EXIT INT TERM' "$RUNNER"
grep -q 'cmp -s' "$RUNNER"
grep -q 'screencapture -x -v' "$RUNNER"
grep -q -- '-T0' "$RUNNER"
grep -q 'window_id "$APP_PID"' "$RUNNER"

echo "playtest_capture_test: PASS"
