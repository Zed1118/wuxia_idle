#!/bin/bash
# T05 verify · lib/ structure audit doc
set -e
DOC="docs/handoff/wuxia_lib_structure_audit_2026-05-17.md"
test -f "$DOC" || { echo "VERIFY FAIL: $DOC missing"; exit 1; }
grep -q "lib/ 目录结构审计" "$DOC" || { echo "VERIFY FAIL: missing title"; exit 1; }
grep -q "CLAUDE.md" "$DOC" || { echo "VERIFY FAIL: missing CLAUDE.md anchor ref"; exit 1; }
grep -q "目录树快照" "$DOC" || { echo "VERIFY FAIL: missing 目录树快照 section"; exit 1; }
grep -q "漂移" "$DOC" || { echo "VERIFY FAIL: missing 漂移 keyword"; exit 1; }
grep -q "features" "$DOC" || { echo "VERIFY FAIL: missing features ref"; exit 1; }
git log -1 --pretty=%s | grep -q "nightshift T05" || { echo "VERIFY FAIL: no nightshift T05 commit"; exit 1; }
flutter pub get >/dev/null 2>&1
dart run build_runner build >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero, continuing"; }
flutter analyze --fatal-infos >/dev/null 2>&1 || { echo "VERIFY FAIL: dart analyze"; exit 1; }
echo "VERIFY PASS: T05"
