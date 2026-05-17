#!/bin/bash
# T04 verify · LineagePanelScreen edge test
set -e
TEST="test/features/character_panel/presentation/lineage_panel_screen_edge_test.dart"
test -f "$TEST" || { echo "VERIFY FAIL: $TEST missing"; exit 1; }
git log -1 --pretty=%s | grep -q "nightshift T04" || { echo "VERIFY FAIL: no nightshift T04 commit"; exit 1; }
flutter pub get >/dev/null 2>&1
dart run build_runner build >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero, continuing"; }
flutter analyze --fatal-infos >/dev/null 2>&1 || { echo "VERIFY FAIL: dart analyze"; exit 1; }
# Run only the new edge test file (fast targeted verify)
flutter test "$TEST" 2>&1 | tail -10
flutter test "$TEST" >/dev/null 2>&1 || { echo "VERIFY FAIL: edge test failed"; exit 1; }
echo "VERIFY PASS: T04"
