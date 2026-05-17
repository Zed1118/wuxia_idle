#!/bin/bash
# T02 verify · widget test pattern audit doc
set -e
DOC="docs/handoff/wuxia_widget_test_pattern_audit_2026-05-17.md"
test -f "$DOC" || { echo "VERIFY FAIL: $DOC missing"; exit 1; }
grep -q "NavigatorObserver" "$DOC" || { echo "VERIFY FAIL: missing NavigatorObserver section"; exit 1; }
grep -q "pumpAndSettle" "$DOC" || { echo "VERIFY FAIL: missing pumpAndSettle audit"; exit 1; }
grep -q "_RecordingNavigatorObserver" "$DOC" || { echo "VERIFY FAIL: missing _RecordingNavigatorObserver pattern"; exit 1; }
git log -1 --pretty=%s | grep -q "nightshift T02" || { echo "VERIFY FAIL: no nightshift T02 commit"; exit 1; }
flutter pub get >/dev/null 2>&1
dart run build_runner build >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero, continuing"; }
flutter analyze --fatal-infos >/dev/null 2>&1 || { echo "VERIFY FAIL: dart analyze"; exit 1; }
echo "VERIFY PASS: T02"
