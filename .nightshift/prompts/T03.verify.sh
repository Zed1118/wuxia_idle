#!/bin/bash
# T03 verify · CharacterPanelScreen 边界 test
set -e
TEST_FILE="test/features/character_panel/presentation/character_panel_screen_edge_test.dart"
test -f "$TEST_FILE" || { echo "VERIFY FAIL: $TEST_FILE missing"; exit 1; }
grep -q "void main()" "$TEST_FILE" || { echo "VERIFY FAIL: no void main() in test"; exit 1; }
grep -q "testWidgets" "$TEST_FILE" || { echo "VERIFY FAIL: no testWidgets in test"; exit 1; }
git log -1 --pretty=%s | grep -q "nightshift T03" || { echo "VERIFY FAIL: no nightshift T03 commit"; exit 1; }
flutter pub get >/dev/null 2>&1
dart run build_runner build >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero, continuing"; }
flutter analyze --fatal-infos >/dev/null 2>&1 || { echo "VERIFY FAIL: dart analyze"; exit 1; }
# Run the new test file (must all pass)
flutter test "$TEST_FILE" 2>&1 | tail -10
flutter test "$TEST_FILE" >/dev/null 2>&1 || { echo "VERIFY FAIL: new edge test not passing"; exit 1; }
echo "VERIFY PASS: T03"
