#!/bin/bash
# T01 verify · HomeFeedScreen 相对时间 4 档 edge test
set -e
TEST_FILE="test/features/home_feed/presentation/home_feed_screen_time_format_test.dart"
test -f "$TEST_FILE" || { echo "VERIFY FAIL: $TEST_FILE missing"; exit 1; }
grep -q "void main()" "$TEST_FILE" || { echo "VERIFY FAIL: no void main()"; exit 1; }
grep -c "testWidgets" "$TEST_FILE" | awk '{ if ($1 < 4) { print "VERIFY FAIL: testWidgets count <4 (got " $1 ")"; exit 1 } }'
git log -1 --pretty=%s | grep -q "nightshift T01" || { echo "VERIFY FAIL: no nightshift T01 commit"; exit 1; }
flutter pub get >/dev/null 2>&1
dart run build_runner build --delete-conflicting-outputs >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero"; }
flutter analyze --fatal-infos >/dev/null 2>&1 || { echo "VERIFY FAIL: dart analyze"; exit 1; }
flutter test "$TEST_FILE" 2>&1 | tail -10
flutter test "$TEST_FILE" >/dev/null 2>&1 || { echo "VERIFY FAIL: new test not passing"; exit 1; }
echo "VERIFY PASS: T01"
