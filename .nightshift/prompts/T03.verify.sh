#!/bin/bash
# T03 verify · techniques.yaml 21 本 description 占位 → 真文案
set -uo pipefail

YAML="data/techniques.yaml"
test -f "$YAML" || { echo "VERIFY FAIL: $YAML missing"; exit 1; }

# 1. 0 占位剩
TODO=$(grep -c "description: TODO_NARRATIVE" "$YAML" || true)
if [ "$TODO" -ne 0 ]; then
  echo "VERIFY FAIL: TODO_NARRATIVE 还有 $TODO 处"
  exit 1
fi

# 2. techniques 总数不变 = 21
COUNT=$(grep -c "^  - id: tech_" "$YAML")
if [ "$COUNT" -ne 21 ]; then
  echo "VERIFY FAIL: techniques count $COUNT != 21"
  exit 1
fi

# 3. 黑名单词 0 命中
for word in legendary epic 史诗 神器 传说级 无敌 最强 究极 霸气 逆天 刀光剑影 血溅; do
  if grep -q "$word" "$YAML"; then
    echo "VERIFY FAIL: 黑名单词 '$word' 出现"
    exit 1
  fi
done

# 4. description 字段计数 = 21(不多不少)
DESC_COUNT=$(grep -c "^    description:" "$YAML")
if [ "$DESC_COUNT" -ne 21 ]; then
  echo "VERIFY FAIL: description 字段 $DESC_COUNT != 21"
  exit 1
fi

# 5. flutter pub get + analyze
flutter pub get >/dev/null 2>&1 || { echo "VERIFY FAIL: pub get"; exit 1; }
dart run build_runner build --delete-conflicting-outputs >/dev/null 2>&1 || echo "VERIFY WARN: build_runner"
flutter analyze --fatal-warnings >/dev/null 2>&1 || { echo "VERIFY FAIL: analyze"; exit 1; }

# 6. techniques loader test pass(若存在)
if [ -f test/data/techniques_loader_test.dart ]; then
  flutter test test/data/techniques_loader_test.dart >/dev/null 2>&1 \
    || { echo "VERIFY FAIL: techniques_loader_test 不通过"; exit 1; }
fi

# 7. commit message
git log -1 --pretty=%s | grep -q "nightshift T03" || { echo "VERIFY FAIL: no nightshift T03 commit"; exit 1; }

# 8. 改动越界
CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD)
CHANGED_OUTSIDE=$(echo "$CHANGED" | grep -vE "^data/techniques\.yaml$|^$" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T03 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T03 (description 21 处全填,techniques=$COUNT)"
