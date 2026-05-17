#!/bin/bash
# T04 verify · BaikeScreen 7 阶分组 + 段数 edge
set -e
TEST_FILE="test/features/baike/presentation/baike_screen_tier_group_test.dart"
test -f "$TEST_FILE" || { echo "VERIFY FAIL: $TEST_FILE missing"; exit 1; }
grep -q "void main()" "$TEST_FILE" || { echo "VERIFY FAIL: no void main()"; exit 1; }
grep -cE "^\s*testWidgets\(" "$TEST_FILE" | awk '{ if ($1 < 4) { print "VERIFY FAIL: testWidgets count <4 (got " $1 ")"; exit 1 } }'
git log -1 --pretty=%s | grep -q "nightshift T04" || { echo "VERIFY FAIL: no nightshift T04 commit"; exit 1; }
flutter pub get >/dev/null 2>&1
dart run build_runner build --delete-conflicting-outputs >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero"; }
flutter analyze --fatal-infos >/dev/null 2>&1 || { echo "VERIFY FAIL: dart analyze"; exit 1; }
flutter test "$TEST_FILE" 2>&1 | tail -10
flutter test "$TEST_FILE" >/dev/null 2>&1 || { echo "VERIFY FAIL: new test not passing"; exit 1; }
echo "VERIFY PASS: T04"
