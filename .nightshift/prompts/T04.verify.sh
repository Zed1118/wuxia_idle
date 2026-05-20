#!/bin/bash
# T04 verify · 武学领悟招式 narrative +5(insights/)
set -uo pipefail

DIR="data/narratives/techniques/insights"
test -d "$DIR" || { echo "VERIFY FAIL: $DIR missing"; exit 1; }

# 1. 5 个新文件都在
for f in tian_xin_ting_yu gu_dao_jian_yi mo_jian_xiang_xin xue_ye_xing_yi chuan_long_xiao_ge; do
  test -f "$DIR/$f.yaml" || { echo "VERIFY FAIL: $DIR/$f.yaml missing"; exit 1; }
done

# 2. 总文件数 = 40
COUNT=$(ls "$DIR"/*.yaml 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" -ne 40 ]; then
  echo "VERIFY FAIL: insights count $COUNT != 40"
  exit 1
fi

# 3. 每文件 4 字段齐 + id 匹配文件名
for f in tian_xin_ting_yu gu_dao_jian_yi mo_jian_xiang_xin xue_ye_xing_yi chuan_long_xiao_ge; do
  FILE="$DIR/$f.yaml"
  grep -q "^id: $f$" "$FILE" || { echo "VERIFY FAIL: $f.yaml id mismatch"; exit 1; }
  grep -q "^name:" "$FILE" || { echo "VERIFY FAIL: $f.yaml no name"; exit 1; }
  grep -q "^description: |" "$FILE" || { echo "VERIFY FAIL: $f.yaml no description"; exit 1; }
  grep -q "^prerequisite_hint: |" "$FILE" || { echo "VERIFY FAIL: $f.yaml no prerequisite_hint"; exit 1; }
done

# 4. 黑名单词 0 命中
for f in tian_xin_ting_yu gu_dao_jian_yi mo_jian_xiang_xin xue_ye_xing_yi chuan_long_xiao_ge; do
  for word in legendary epic 史诗 神器 传说级 无敌 最强 究极 霸气 逆天 刀光剑影 血溅; do
    if grep -q "$word" "$DIR/$f.yaml"; then
      echo "VERIFY FAIL: $f.yaml 含黑名单词 '$word'"
      exit 1
    fi
  done
done

# 5. 长度 ≤ 30 行 per file(2-4 行 desc + 1-2 行 hint + 4 行 head/blank)
for f in tian_xin_ting_yu gu_dao_jian_yi mo_jian_xiang_xin xue_ye_xing_yi chuan_long_xiao_ge; do
  LINES=$(wc -l < "$DIR/$f.yaml" | tr -d ' ')
  if [ "$LINES" -gt 30 ]; then
    echo "VERIFY FAIL: $f.yaml $LINES 行 > 30"
    exit 1
  fi
done

# 6. flutter 工具链
flutter pub get >/dev/null 2>&1 || { echo "VERIFY FAIL: pub get"; exit 1; }
flutter analyze --fatal-warnings >/dev/null 2>&1 || { echo "VERIFY FAIL: analyze"; exit 1; }

# 7. commit message
git log -1 --pretty=%s | grep -q "nightshift T04" || { echo "VERIFY FAIL: no nightshift T04 commit"; exit 1; }

# 8. 改动越界
CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD)
CHANGED_OUTSIDE=$(echo "$CHANGED" | grep -vE "^data/narratives/techniques/insights/[a-z_]+\.yaml$|^$" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T04 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T04 (insights=$COUNT, 5 new files)"
