#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARTIFACT_DIR="${1:-docs/handoff/visual_acceptance_2026-06-30}"
PYCACHE_DIR="$(mktemp -d)"
trap 'rm -rf "$PYCACHE_DIR"' EXIT

cd "$ROOT_DIR"

echo "== Visual acceptance final gate =="
date '+%Y-%m-%d %H:%M:%S %Z'

echo
echo "== Git status =="
git status --short || true

echo
echo "== Artifact audit =="
PYTHONPYCACHEPREFIX="$PYCACHE_DIR" python3 tools/visual_capture/audit_visual_acceptance.py "$ARTIFACT_DIR"

echo
echo "== Paper text contrast audit =="
PYTHONPYCACHEPREFIX="$PYCACHE_DIR" python3 tools/audit_paper_text_contrast.py --root "$ROOT_DIR"

echo
echo "== Script syntax =="
PYTHONPYCACHEPREFIX="$PYCACHE_DIR" python3 -m py_compile \
  tools/audit_paper_text_contrast.py \
  tools/visual_capture/audit_visual_acceptance.py \
  tools/visual_capture/analyze_visual_density.py
bash -n tools/visual_capture/visual_capture.sh

echo
echo "== Capture dry-run =="
tools/visual_capture/visual_capture.sh \
  --route main_menu \
  --resolutions 1920x1080 \
  --output /tmp/wuxia_visual_probe \
  --dry-run

echo
echo "== Stale Python bytecode =="
stale_bytecode="$(
  find tools \( -name '__pycache__' -o -name '*.pyc' \) -print
)"
if [[ -n "$stale_bytecode" ]]; then
  echo "$stale_bytecode"
  exit 1
fi
echo "none"

echo
echo "== Machine status =="
PYTHONPYCACHEPREFIX="$PYCACHE_DIR" python3 - "$ARTIFACT_DIR/visual_acceptance_status.json" <<'PY'
import json
import sys
from pathlib import Path

status_path = Path(sys.argv[1])
status = json.loads(status_path.read_text(encoding="utf-8"))
if not status.get("ok"):
    raise SystemExit(f"{status_path} reports ok=false")
print(f"{status_path}: ok=true")
PY

echo
echo "Final gate machine checks passed. If current time is before 2026-06-30 09:00 CST, keep the goal active."
