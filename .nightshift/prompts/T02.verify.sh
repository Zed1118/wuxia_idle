#!/bin/bash
# T02 verify · equipment id ↔ lore yaml 一致性扫描 doc
set -e
DOC="docs/handoff/wuxia_equipment_lore_id_consistency_2026-05-17.md"
test -f "$DOC" || { echo "VERIFY FAIL: $DOC missing"; exit 1; }
grep -q "equipment id ↔ lore yaml" "$DOC" || { echo "VERIFY FAIL: missing title"; exit 1; }
grep -q "equipment.yaml" "$DOC" || { echo "VERIFY FAIL: missing equipment.yaml ref"; exit 1; }
grep -q "data/lore" "$DOC" || { echo "VERIFY FAIL: missing data/lore ref"; exit 1; }
grep -q "双向对账" "$DOC" || { echo "VERIFY FAIL: missing section 双向对账"; exit 1; }
grep -q "7 阶分布" "$DOC" || { echo "VERIFY FAIL: missing section 7 阶分布"; exit 1; }
git log -1 --pretty=%s | grep -q "nightshift T02" || { echo "VERIFY FAIL: no nightshift T02 commit"; exit 1; }
flutter pub get >/dev/null 2>&1
dart run build_runner build >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero, continuing"; }
flutter analyze --fatal-infos >/dev/null 2>&1 || { echo "VERIFY FAIL: dart analyze"; exit 1; }
echo "VERIFY PASS: T02"
