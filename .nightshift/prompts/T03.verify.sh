#!/bin/bash
# T03 verify · dead code scan report
set -e
DOC="docs/handoff/wuxia_dead_code_scan_2026-05-17.md"
test -f "$DOC" || { echo "VERIFY FAIL: $DOC missing"; exit 1; }
grep -q "死 provider" "$DOC" || { echo "VERIFY FAIL: missing dead provider section"; exit 1; }
grep -q "0-lib-consumer" "$DOC" || { echo "VERIFY FAIL: missing 0-consumer service section"; exit 1; }
grep -q "extension" "$DOC" || { echo "VERIFY FAIL: missing extension section"; exit 1; }
grep -q "总结" "$DOC" || { echo "VERIFY FAIL: missing summary section"; exit 1; }
git log -1 --pretty=%s | grep -q "nightshift T03" || { echo "VERIFY FAIL: no nightshift T03 commit"; exit 1; }
flutter pub get >/dev/null 2>&1
dart run build_runner build >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero, continuing"; }
flutter analyze --fatal-infos >/dev/null 2>&1 || { echo "VERIFY FAIL: dart analyze"; exit 1; }
echo "VERIFY PASS: T03"
