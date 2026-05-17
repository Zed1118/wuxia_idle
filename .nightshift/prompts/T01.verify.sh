#!/bin/bash
# T01 verify · encounter id 一致性扫描 doc
set -e
DOC="docs/handoff/wuxia_encounter_id_consistency_2026-05-17.md"
test -f "$DOC" || { echo "VERIFY FAIL: $DOC missing"; exit 1; }
grep -q "encounter id 一致性扫描" "$DOC" || { echo "VERIFY FAIL: missing title"; exit 1; }
grep -q "encounters.yaml" "$DOC" || { echo "VERIFY FAIL: missing encounters.yaml ref"; exit 1; }
grep -q "data/events" "$DOC" || { echo "VERIFY FAIL: missing data/events ref"; exit 1; }
grep -q "_archive" "$DOC" || { echo "VERIFY FAIL: missing _archive ref"; exit 1; }
grep -q "双向对账" "$DOC" || { echo "VERIFY FAIL: missing section 双向对账"; exit 1; }
# Verify task did commit
git log -1 --pretty=%s | grep -q "nightshift T01" || { echo "VERIFY FAIL: no nightshift T01 commit on branch"; exit 1; }
# Project still healthy (no lib/ changes per scope)
flutter pub get >/dev/null 2>&1
dart run build_runner build >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero, continuing"; }
flutter analyze --fatal-infos 2>&1 | tail -5
flutter analyze --fatal-infos >/dev/null 2>&1 || { echo "VERIFY FAIL: dart analyze"; exit 1; }
echo "VERIFY PASS: T01"
