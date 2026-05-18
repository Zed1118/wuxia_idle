#!/bin/bash
# T05 verify · CodexTab widget test 加固
set -uo pipefail
TEST_FILE="test/features/codex/presentation/codex_tab_test.dart"
test -f "$TEST_FILE" || { echo "VERIFY FAIL: $TEST_FILE missing"; exit 1; }
grep -q "void main()" "$TEST_FILE" || { echo "VERIFY FAIL: no void main()"; exit 1; }

# 1. testWidgets count ≥ 12
COUNT=$(grep -c "testWidgets(" "$TEST_FILE")
if [ "$COUNT" -lt 12 ]; then
  echo "VERIFY FAIL: testWidgets count $COUNT < 12"
  exit 1
fi

# 2. 行数 ≥ 160
LINES=$(wc -l < "$TEST_FILE" | tr -d ' ')
if [ "$LINES" -lt 160 ]; then
  echo "VERIFY FAIL: test file $LINES 行 < 160"
  exit 1
fi

# 3. ListView viewport 体例必用
grep -q "setSurfaceSize" "$TEST_FILE" || { echo "VERIFY FAIL: setSurfaceSize 体例缺(ListView viewport 红线)"; exit 1; }
grep -q "addTearDown" "$TEST_FILE" || { echo "VERIFY FAIL: addTearDown 缺(viewport teardown 红线)"; exit 1; }

# 4. 数字派生体例(不写死 12 机制 / 7 lore)
grep -qE "mechanicCount|loreCount|\.length" "$TEST_FILE" || { echo "VERIFY FAIL: 派生计数体例缺(memory feedback_red_line_test_semantics)"; exit 1; }

# 5. flutter 工具链
flutter pub get >/dev/null 2>&1 || { echo "VERIFY FAIL: pub get"; exit 1; }
dart run build_runner build --delete-conflicting-outputs >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero"; }

# 6. analyze --fatal-errors
flutter analyze --fatal-errors >/dev/null 2>&1 || { echo "VERIFY FAIL: analyze"; exit 1; }

# 7. feature-local test pass
flutter test "$TEST_FILE" 2>&1 | tail -10
flutter test "$TEST_FILE" >/dev/null 2>&1 || { echo "VERIFY FAIL: $TEST_FILE 不通过"; exit 1; }

# 8. commit message check
git log -1 --pretty=%s | grep -q "nightshift T05" || { echo "VERIFY FAIL: no nightshift T05 commit"; exit 1; }

# 9. 仅 test/features/codex/ 改动
CHANGED_OUTSIDE=$(git show --name-only HEAD | grep -vE "^commit|^Author|^Date|^test/features/codex/|^$|^test\(nightshift" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T05 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T05 (testWidgets $COUNT, $LINES 行)"
