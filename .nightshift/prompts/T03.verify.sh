#!/bin/bash
# T03 verify · #37 6 orphan event 决议归档
set -uo pipefail
TARGET="docs/handoff/p1_37_orphan_decree_2026-05-19.md"
test -f "$TARGET" || { echo "VERIFY FAIL: $TARGET missing"; exit 1; }

# 1. 行数 ≤ 100 + 20% buffer
LINES=$(wc -l < "$TARGET" | tr -d ' ')
if [ "$LINES" -gt 120 ]; then
  echo "VERIFY FAIL: decree md $LINES 行 > 120 严重超 100"
  exit 1
fi

# 2. 4 段结构齐
for section in "§1" "§2" "§3" "§4"; do
  grep -q "$section" "$TARGET" || { echo "VERIFY FAIL: 段 '$section' 缺"; exit 1; }
done

# 3. 6 orphan id 全提及
for orphan in "duan_qiao_can_yue" "gu_chuan_deng_ying" "huang_cun_yao_ren" "lao_jing_hui_xiang" "qing_lou_can_meng" "yu_zhong_qiao_men"; do
  grep -q "$orphan" "$TARGET" || { echo "VERIFY FAIL: orphan $orphan 未审"; exit 1; }
done

# 4. 决议关键词(挂回 OR 永封档)出现
grep -qE "挂回|永封档|永久归档" "$TARGET" || { echo "VERIFY FAIL: 决议关键词缺"; exit 1; }

# 5. yaml 未被改动(钉死)
git diff --name-only HEAD~1 | grep -E "^data/(encounters\.yaml|events/)" && {
  echo "VERIFY FAIL: T03 改动 data/encounters.yaml 或 data/events/ 违反钉死红线"
  exit 1
} || true

# 6. commit message check
git log -1 --pretty=%s | grep -q "nightshift T03" || { echo "VERIFY FAIL: no nightshift T03 commit"; exit 1; }

# 7. 仅 docs/handoff/ 改动
CHANGED_OUTSIDE=$(git show --name-only HEAD | grep -vE "^commit|^Author|^Date|^docs/handoff/|^$|^docs\(nightshift" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T03 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T03 (decree md $LINES 行)"
