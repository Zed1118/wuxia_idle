#!/bin/bash
# T03 verify · markAllFeedRead 边界 edge
set -e
TEST_FILE="test/features/home_feed/application/home_feed_providers_mark_all_edge_test.dart"
test -f "$TEST_FILE" || { echo "VERIFY FAIL: $TEST_FILE missing"; exit 1; }
grep -q "void main()" "$TEST_FILE" || { echo "VERIFY FAIL: no void main()"; exit 1; }
grep -cE "^\s*(test|testWidgets)\(" "$TEST_FILE" | awk '{ if ($1 < 3) { print "VERIFY FAIL: test count <3 (got " $1 ")"; exit 1 } }'
git log -1 --pretty=%s | grep -q "nightshift T03" || { echo "VERIFY FAIL: no nightshift T03 commit"; exit 1; }
flutter pub get >/dev/null 2>&1
dart run build_runner build --delete-conflicting-outputs >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero"; }
flutter analyze --fatal-infos >/dev/null 2>&1 || { echo "VERIFY FAIL: dart analyze"; exit 1; }
flutter test "$TEST_FILE" 2>&1 | tail -10
flutter test "$TEST_FILE" >/dev/null 2>&1 || { echo "VERIFY FAIL: new test not passing"; exit 1; }
echo "VERIFY PASS: T03"
