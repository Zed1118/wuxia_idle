#!/bin/bash
# T06 verify · 心法 narrative +4
set -uo pipefail

DIR="data/narratives/techniques"
test -d "$DIR" || { echo "VERIFY FAIL: $DIR missing"; exit 1; }

# 1. 4 个新文件都在
for f in bing_pian_xin_jue chi_yang_jin_gang_quan liu_yun_qing_ling_shen_fa tai_yi_xuan_shen_jue; do
  test -f "$DIR/$f.yaml" || { echo "VERIFY FAIL: $DIR/$f.yaml missing"; exit 1; }
done

# 2. 顶层 yaml 总数 = 26(只数 *.yaml,不含 insights/ 子目录)
COUNT=$(ls "$DIR"/*.yaml 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" -ne 26 ]; then
  echo "VERIFY FAIL: techniques narrative count $COUNT != 26"
  exit 1
fi

# 3. 每文件结构齐
for f in bing_pian_xin_jue chi_yang_jin_gang_quan liu_yun_qing_ling_shen_fa tai_yi_xuan_shen_jue; do
  FILE="$DIR/$f.yaml"
  grep -q "^id: $f$" "$FILE" || { echo "VERIFY FAIL: $f.yaml id mismatch"; exit 1; }
  grep -q "^name:" "$FILE" || { echo "VERIFY FAIL: $f.yaml no name"; exit 1; }
  grep -q "^origin: |" "$FILE" || { echo "VERIFY FAIL: $f.yaml no origin"; exit 1; }
  grep -q "^moves:" "$FILE" || { echo "VERIFY FAIL: $f.yaml no moves"; exit 1; }
  # 3 招 moves
  MOVE_COUNT=$(grep -cE "^  - id:" "$FILE")
  if [ "$MOVE_COUNT" -ne 3 ]; then
    echo "VERIFY FAIL: $f.yaml moves count $MOVE_COUNT != 3"
    exit 1
  fi
done

# 4. 黑名单词
for f in bing_pian_xin_jue chi_yang_jin_gang_quan liu_yun_qing_ling_shen_fa tai_yi_xuan_shen_jue; do
  for word in legendary epic 史诗 神器 传说级 无敌 最强 究极 霸气 逆天 刀光剑影 血溅; do
    if grep -q "$word" "$DIR/$f.yaml"; then
      echo "VERIFY FAIL: $f.yaml 含黑名单词 '$word'"
      exit 1
    fi
  done
done

# 5. 长度 50-100 行
for f in bing_pian_xin_jue chi_yang_jin_gang_quan liu_yun_qing_ling_shen_fa tai_yi_xuan_shen_jue; do
  LINES=$(wc -l < "$DIR/$f.yaml" | tr -d ' ')
  if [ "$LINES" -lt 30 ] || [ "$LINES" -gt 120 ]; then
    echo "VERIFY FAIL: $f.yaml $LINES 行 不在 30-120 范围"
    exit 1
  fi
done

# 6. flutter 工具链
flutter pub get >/dev/null 2>&1 || { echo "VERIFY FAIL: pub get"; exit 1; }
flutter analyze --fatal-warnings >/dev/null 2>&1 || { echo "VERIFY FAIL: analyze"; exit 1; }

# 7. commit message
git log -1 --pretty=%s | grep -q "nightshift T06" || { echo "VERIFY FAIL: no nightshift T06 commit"; exit 1; }

# 8. 改动越界(只允许 4 个新 yaml,不允许动 insights/)
CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD)
CHANGED_OUTSIDE=$(echo "$CHANGED" | grep -vE "^data/narratives/techniques/(bing_pian_xin_jue|chi_yang_jin_gang_quan|liu_yun_qing_ling_shen_fa|tai_yi_xuan_shen_jue)\.yaml$|^$" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T06 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T06 (techniques narrative=$COUNT, 4 new files)"
