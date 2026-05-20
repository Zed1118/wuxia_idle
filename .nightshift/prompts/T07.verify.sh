#!/bin/bash
# T07 verify · Phase 5+ 师徒升级 spec 起草
set -uo pipefail

TARGET="docs/handoff/phase5_master_disciple_spec_2026-05-20.md"
test -f "$TARGET" || { echo "VERIFY FAIL: $TARGET missing"; exit 1; }

# 1. 行数 ≤ 96(允许 +20% buffer)
LINES=$(wc -l < "$TARGET" | tr -d ' ')
if [ "$LINES" -gt 96 ]; then
  echo "VERIFY FAIL: $LINES > 96 行"
  exit 1
fi
if [ "$LINES" -lt 30 ]; then
  echo "VERIFY FAIL: $LINES < 30 行(太少)"
  exit 1
fi

# 2. 6 段结构齐
for section in "§1 当前状态" "§2" "§3 飞升机制" "§4 祖师爷" "§5" "§6 closeout"; do
  grep -q "$section" "$TARGET" || { echo "VERIFY FAIL: 段 '$section' 缺"; exit 1; }
done

# 3. 关键关键词
for kw in "ascend_to_wusheng" "player_pick" "stack_across_generations" "auto_swap"; do
  grep -q "$kw" "$TARGET" || { echo "VERIFY FAIL: 关键词 '$kw' 缺"; exit 1; }
done

# 4. commit message
git log -1 --pretty=%s | grep -q "nightshift T07" || { echo "VERIFY FAIL: no nightshift T07 commit"; exit 1; }

# 5. 改动越界
CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD)
CHANGED_OUTSIDE=$(echo "$CHANGED" | grep -vE "^docs/handoff/phase5_master_disciple_spec_2026-05-20\.md$|^$" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T07 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T07 (spec $LINES 行,6 段齐)"
