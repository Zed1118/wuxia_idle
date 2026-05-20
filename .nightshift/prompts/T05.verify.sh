#!/bin/bash
# T05 verify · 基础奇遇 events narrative +4
set -uo pipefail

DIR="data/events"
test -d "$DIR" || { echo "VERIFY FAIL: $DIR missing"; exit 1; }

# 1. 4 个新文件都在
for f in qin_lou_fang_you gu_si_qiu_shu ma_kuai_song_hua xian_zhou_yi_lu; do
  test -f "$DIR/$f.yaml" || { echo "VERIFY FAIL: $DIR/$f.yaml missing"; exit 1; }
done

# 2. events 顶层文件数 = 50(原 46 + 4)
COUNT=$(ls "$DIR"/*.yaml 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" -ne 50 ]; then
  echo "VERIFY FAIL: events count $COUNT != 50"
  exit 1
fi

# 3. 每文件结构齐(id / title / opening / choices)
for f in qin_lou_fang_you gu_si_qiu_shu ma_kuai_song_hua xian_zhou_yi_lu; do
  FILE="$DIR/$f.yaml"
  grep -q "^id: $f$" "$FILE" || { echo "VERIFY FAIL: $f.yaml id mismatch"; exit 1; }
  grep -q "^title:" "$FILE" || { echo "VERIFY FAIL: $f.yaml no title"; exit 1; }
  grep -q "^opening: |" "$FILE" || { echo "VERIFY FAIL: $f.yaml no opening"; exit 1; }
  grep -q "^choices:" "$FILE" || { echo "VERIFY FAIL: $f.yaml no choices"; exit 1; }
  # 3 个 outcome_id
  OUTCOME_COUNT=$(grep -c "outcome_id:" "$FILE")
  if [ "$OUTCOME_COUNT" -ne 3 ]; then
    echo "VERIFY FAIL: $f.yaml outcome_id count $OUTCOME_COUNT != 3"
    exit 1
  fi
  # 必须有 skip outcome
  grep -q "outcome_id: skip" "$FILE" || { echo "VERIFY FAIL: $f.yaml 无 skip outcome"; exit 1; }
done

# 4. 必要 outcome_id 钉死匹配 T02 outcomeMapping
grep -q "outcome_id: qin_he" "$DIR/qin_lou_fang_you.yaml" || { echo "VERIFY FAIL: qin_he 缺"; exit 1; }
grep -q "outcome_id: qin_du" "$DIR/qin_lou_fang_you.yaml" || { echo "VERIFY FAIL: qin_du 缺"; exit 1; }
grep -q "outcome_id: seng_shou" "$DIR/gu_si_qiu_shu.yaml" || { echo "VERIFY FAIL: seng_shou 缺"; exit 1; }
grep -q "outcome_id: seng_zhi" "$DIR/gu_si_qiu_shu.yaml" || { echo "VERIFY FAIL: seng_zhi 缺"; exit 1; }
grep -q "outcome_id: shou_xin" "$DIR/ma_kuai_song_hua.yaml" || { echo "VERIFY FAIL: shou_xin 缺"; exit 1; }
grep -q "outcome_id: huan_yi" "$DIR/ma_kuai_song_hua.yaml" || { echo "VERIFY FAIL: huan_yi 缺"; exit 1; }
grep -q "outcome_id: lu_yu" "$DIR/xian_zhou_yi_lu.yaml" || { echo "VERIFY FAIL: lu_yu 缺"; exit 1; }
grep -q "outcome_id: lu_xing" "$DIR/xian_zhou_yi_lu.yaml" || { echo "VERIFY FAIL: lu_xing 缺"; exit 1; }

# 5. 黑名单词
for f in qin_lou_fang_you gu_si_qiu_shu ma_kuai_song_hua xian_zhou_yi_lu; do
  for word in legendary epic 史诗 神器 传说级 无敌 最强 究极 霸气 逆天 刀光剑影 血溅; do
    if grep -q "$word" "$DIR/$f.yaml"; then
      echo "VERIFY FAIL: $f.yaml 含黑名单词 '$word'"
      exit 1
    fi
  done
done

# 6. 长度 ≤ 60 行 per file
for f in qin_lou_fang_you gu_si_qiu_shu ma_kuai_song_hua xian_zhou_yi_lu; do
  LINES=$(wc -l < "$DIR/$f.yaml" | tr -d ' ')
  if [ "$LINES" -gt 60 ]; then
    echo "VERIFY FAIL: $f.yaml $LINES 行 > 60"
    exit 1
  fi
done

# 7. flutter 工具链
flutter pub get >/dev/null 2>&1 || { echo "VERIFY FAIL: pub get"; exit 1; }
flutter analyze --fatal-warnings >/dev/null 2>&1 || { echo "VERIFY FAIL: analyze"; exit 1; }

# 8. commit message
git log -1 --pretty=%s | grep -q "nightshift T05" || { echo "VERIFY FAIL: no nightshift T05 commit"; exit 1; }

# 9. 改动越界
CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD)
CHANGED_OUTSIDE=$(echo "$CHANGED" | grep -vE "^data/events/[a-z_]+\.yaml$|^$" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T05 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T05 (events=$COUNT, 4 new files)"
