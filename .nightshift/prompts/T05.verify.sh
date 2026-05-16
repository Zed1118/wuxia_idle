#!/bin/bash
# T05 verify · NavigatorObserver mock pattern doc
set -e
DOC="docs/handoff/wuxia_navigator_observer_mock_pattern_2026-05-17.md"
test -f "$DOC" || { echo "VERIFY FAIL: $DOC missing"; exit 1; }
grep -q "_RecordingNavigatorObserver" "$DOC" || { echo "VERIFY FAIL: missing _RecordingNavigatorObserver code block"; exit 1; }
grep -q "pumpAndSettle" "$DOC" || { echo "VERIFY FAIL: missing pumpAndSettle context"; exit 1; }
grep -q "单帧" "$DOC" || { echo "VERIFY FAIL: missing 单帧 description"; exit 1; }
grep -q "#28" "$DOC" || { echo "VERIFY FAIL: missing #28 comparison"; exit 1; }
git log -1 --pretty=%s | grep -q "nightshift T05" || { echo "VERIFY FAIL: no nightshift T05 commit"; exit 1; }
flutter pub get >/dev/null 2>&1
flutter analyze --fatal-infos >/dev/null 2>&1 || { echo "VERIFY FAIL: dart analyze"; exit 1; }
echo "VERIFY PASS: T05"
