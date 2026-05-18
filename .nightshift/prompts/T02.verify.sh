#!/bin/bash
# T02 verify · #43 高阶占位 audit
set -uo pipefail
TARGET="docs/handoff/p1_43_higher_tier_placeholders_audit_2026-05-19.md"
test -f "$TARGET" || { echo "VERIFY FAIL: $TARGET missing"; exit 1; }

# 1. 行数 ≤ 80
LINES=$(wc -l < "$TARGET" | tr -d ' ')
if [ "$LINES" -gt 80 ]; then
  echo "VERIFY WARN: audit md $LINES 行 > 80(spec 限定 ≤ 80,允许 +20% buffer)"
  if [ "$LINES" -gt 96 ]; then
    echo "VERIFY FAIL: audit md $LINES 行严重超 80"
    exit 1
  fi
fi

# 2. 4 段结构齐
for section in "§1 占位现状" "§2 风险评估" "§3 推荐" "§4 closeout"; do
  grep -q "$section" "$TARGET" || { echo "VERIFY FAIL: 段 '$section' 缺"; exit 1; }
done

# 3. 关键 yaml path 提及(grep 实测痕迹)
grep -qE "equipment.yaml|drop_source_tags" "$TARGET" || { echo "VERIFY FAIL: equipment 占位未审"; exit 1; }
grep -qE "towers.yaml|21-30|stage_2[1-9]|stage_30" "$TARGET" || { echo "VERIFY FAIL: towers 21-30 未审"; exit 1; }

# 4. commit message check
git log -1 --pretty=%s | grep -q "nightshift T02" || { echo "VERIFY FAIL: no nightshift T02 commit"; exit 1; }

# 5. 仅 docs/handoff/ 改动(无 lib/data/test 误触)
CHANGED_OUTSIDE=$(git show --name-only HEAD | grep -v "^commit\|^Author\|^Date\|^docs/handoff/\|^$\|^docs(nightshift" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T02 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T02 (audit md $LINES 行)"
