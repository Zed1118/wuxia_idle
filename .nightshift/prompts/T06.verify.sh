#!/bin/bash
# T06 verify · TutorialBannerCard widget test 边界 +5
set -uo pipefail
TEST_FILE="test/features/tutorial/presentation/tutorial_banner_card_test.dart"
test -f "$TEST_FILE" || { echo "VERIFY FAIL: $TEST_FILE missing"; exit 1; }

# 1. test + testWidgets 总数 ≥ 8
COUNT_T=$(grep -cE "testWidgets\(|^\s*test\(" "$TEST_FILE" || true)
if [ "$COUNT_T" -lt 8 ]; then
  echo "VERIFY FAIL: test + testWidgets total $COUNT_T < 8"
  exit 1
fi

# 2. 行数 ≥ 130
LINES=$(wc -l < "$TEST_FILE" | tr -d ' ')
if [ "$LINES" -lt 130 ]; then
  echo "VERIFY FAIL: test file $LINES 行 < 130"
  exit 1
fi

# 3. flutter 工具链
flutter pub get >/dev/null 2>&1 || { echo "VERIFY FAIL: pub get"; exit 1; }
dart run build_runner build --delete-conflicting-outputs >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero"; }

# 4. analyze --fatal-errors
flutter analyze --fatal-errors >/dev/null 2>&1 || { echo "VERIFY FAIL: analyze"; exit 1; }

# 5. feature-local test pass
flutter test "$TEST_FILE" 2>&1 | tail -10
flutter test "$TEST_FILE" >/dev/null 2>&1 || { echo "VERIFY FAIL: $TEST_FILE 不通过"; exit 1; }

# 6. commit message check
git log -1 --pretty=%s | grep -q "nightshift T06" || { echo "VERIFY FAIL: no nightshift T06 commit"; exit 1; }

# 7. 仅 test/features/tutorial/ 改动
CHANGED_OUTSIDE=$(git show --name-only HEAD | grep -vE "^commit|^Author|^Date|^test/features/tutorial/|^$|^test\(nightshift" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T06 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T06 ($COUNT_T cases, $LINES 行)"
