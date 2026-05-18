#!/bin/bash
# T04 verify · CodexEntryDetail widget test 加固
set -uo pipefail
TEST_FILE="test/features/codex/presentation/codex_entry_detail_test.dart"
test -f "$TEST_FILE" || { echo "VERIFY FAIL: $TEST_FILE missing"; exit 1; }
grep -q "void main()" "$TEST_FILE" || { echo "VERIFY FAIL: no void main()"; exit 1; }

# 1. testWidgets count ≥ 10
COUNT=$(grep -c "testWidgets(" "$TEST_FILE")
if [ "$COUNT" -lt 10 ]; then
  echo "VERIFY FAIL: testWidgets count $COUNT < 10"
  exit 1
fi

# 2. 行数扩到 ≥ 80
LINES=$(wc -l < "$TEST_FILE" | tr -d ' ')
if [ "$LINES" -lt 80 ]; then
  echo "VERIFY FAIL: test file $LINES 行 < 80"
  exit 1
fi

# 3. flutter 工具链
flutter pub get >/dev/null 2>&1 || { echo "VERIFY FAIL: pub get"; exit 1; }
dart run build_runner build --delete-conflicting-outputs >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero"; }

# 4. analyze --fatal-errors(不阻塞 info,memory feedback_nightshift_verify_lint_severity)
flutter analyze --fatal-errors >/dev/null 2>&1 || { echo "VERIFY FAIL: analyze"; exit 1; }

# 5. feature-local test pass(memory feedback_workflow_speed_levers Lever 1)
flutter test "$TEST_FILE" 2>&1 | tail -10
flutter test "$TEST_FILE" >/dev/null 2>&1 || { echo "VERIFY FAIL: $TEST_FILE 不通过"; exit 1; }

# 6. commit message check
git log -1 --pretty=%s | grep -q "nightshift T04" || { echo "VERIFY FAIL: no nightshift T04 commit"; exit 1; }

# 7. 仅 test/features/codex/ 改动
CHANGED_OUTSIDE=$(git show --name-only HEAD | grep -vE "^commit|^Author|^Date|^test/features/codex/|^$|^test\(nightshift" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T04 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T04 (testWidgets $COUNT, $LINES 行)"
