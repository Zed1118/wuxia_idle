#!/bin/bash
# T01 verify · #37 永封档 doc
set -e
DOC="docs/handoff/wuxia_w17_orphan_events_permanent_archive_2026-05-17.md"
test -f "$DOC" || { echo "VERIFY FAIL: $DOC missing"; exit 1; }
grep -q "永久封档" "$DOC" || { echo "VERIFY FAIL: missing key '永久封档'"; exit 1; }
grep -q "duan_qiao_can_yue" "$DOC" || { echo "VERIFY FAIL: missing file ref duan_qiao_can_yue"; exit 1; }
grep -q "yu_zhong_qiao_men" "$DOC" || { echo "VERIFY FAIL: missing file ref yu_zhong_qiao_men"; exit 1; }
grep -q "PROGRESS 销账建议" "$DOC" || { echo "VERIFY FAIL: missing section 'PROGRESS 销账建议'"; exit 1; }
# Verify task did commit
git log -1 --pretty=%s | grep -q "nightshift T01" || { echo "VERIFY FAIL: no nightshift T01 commit on branch"; exit 1; }
# Project still healthy (no lib/ changes per scope)
flutter pub get >/dev/null 2>&1
flutter analyze --fatal-infos 2>&1 | tail -5
flutter analyze --fatal-infos >/dev/null 2>&1 || { echo "VERIFY FAIL: dart analyze"; exit 1; }
echo "VERIFY PASS: T01"
