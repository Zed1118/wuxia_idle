#!/bin/bash
# T01 verify · 心法相生 +3 + 红线 test
set -uo pipefail

YAML="data/synergies.yaml"
TEST="test/balance/synergy_hot_loop_upgrade_test.dart"

test -f "$YAML" || { echo "VERIFY FAIL: $YAML missing"; exit 1; }
test -f "$TEST" || { echo "VERIFY FAIL: $TEST missing"; exit 1; }

# 1. synergies 总数 = 8
COUNT=$(grep -c "^  - id: synergy_" "$YAML")
if [ "$COUNT" -ne 8 ]; then
  echo "VERIFY FAIL: synergies count $COUNT != 8"
  exit 1
fi

# 2. 3 个新 id 都在
for id in synergy_gang_yin_hu_zhi synergy_ling_gang_hui_liu synergy_ling_yin_gui_yi; do
  grep -q "id: $id" "$YAML" || { echo "VERIFY FAIL: $id missing"; exit 1; }
done

# 3. hot-loop C1/C2/C3 test 都在
for tag in "hot-loop C1" "hot-loop C2" "hot-loop C3"; do
  grep -q "$tag" "$TEST" || { echo "VERIFY FAIL: '$tag' missing"; exit 1; }
done

# 4. flutter 工具链
flutter pub get >/dev/null 2>&1 || { echo "VERIFY FAIL: pub get"; exit 1; }
dart run build_runner build --delete-conflicting-outputs >/dev/null 2>&1 || echo "VERIFY WARN: build_runner non-zero"

# 5. analyze --fatal-warnings(不 --fatal-infos,memory feedback_flutter_analyze_fatal_errors_invalid)
flutter analyze --fatal-warnings >/dev/null 2>&1 || { echo "VERIFY FAIL: analyze"; exit 1; }

# 6. 局部 test pass(synergy 3 个相关 test 文件)
flutter test test/data/defs/synergy_def_test.dart >/dev/null 2>&1 \
  || { echo "VERIFY FAIL: synergy_def_test 不通过"; exit 1; }
flutter test "$TEST" >/dev/null 2>&1 \
  || { echo "VERIFY FAIL: synergy_hot_loop_upgrade_test 不通过"; exit 1; }
flutter test test/features/cultivation/application/synergy_service_test.dart >/dev/null 2>&1 \
  || { echo "VERIFY FAIL: synergy_service_test 不通过"; exit 1; }

# 7. commit message
git log -1 --pretty=%s | grep -q "nightshift T01" || { echo "VERIFY FAIL: no nightshift T01 commit"; exit 1; }

# 8. 改动越界(memory feedback_nightshift_verify_changedoutside_bug 用 git diff-tree)
CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD)
CHANGED_OUTSIDE=$(echo "$CHANGED" | grep -vE "^data/synergies\.yaml$|^test/balance/synergy_hot_loop_upgrade_test\.dart$|^$" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T01 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T01 (synergies=$COUNT, 3 hot-loop C cases)"
