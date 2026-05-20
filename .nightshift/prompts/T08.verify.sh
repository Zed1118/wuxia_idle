#!/bin/bash
# T08 verify · Demo §8.4 polish closeout
set -uo pipefail

TARGET="docs/handoff/p1_45_demo_polish_closeout_2026-05-20.md"
test -f "$TARGET" || { echo "VERIFY FAIL: $TARGET missing"; exit 1; }

# 1. 行数 100-180
LINES=$(wc -l < "$TARGET" | tr -d ' ')
if [ "$LINES" -lt 60 ] || [ "$LINES" -gt 200 ]; then
  echo "VERIFY FAIL: $LINES 行不在 60-200 范围"
  exit 1
fi

# 2. 7 段结构齐
for section in "§1 Nightshift" "§2 Baseline" "§3 Demo §8.4" "§4 早上 cherry-pick" "§5 风险" "§6" "§7 下波候选"; do
  grep -q "$section" "$TARGET" || { echo "VERIFY FAIL: 段 '$section' 缺"; exit 1; }
done

# 3. cherry-pick 命令存在(Phase C 必须含 git cherry-pick)
grep -q "git cherry-pick" "$TARGET" || { echo "VERIFY FAIL: 无 cherry-pick 命令"; exit 1; }

# 4. 8 task 列全
for t in T01 T02 T03 T04 T05 T06 T07 T08; do
  grep -q "$t" "$TARGET" || { echo "VERIFY FAIL: $t 未提及"; exit 1; }
done

# 5. commit message
git log -1 --pretty=%s | grep -q "nightshift T08" || { echo "VERIFY FAIL: no nightshift T08 commit"; exit 1; }

# 6. 改动越界
CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD)
CHANGED_OUTSIDE=$(echo "$CHANGED" | grep -vE "^docs/handoff/p1_45_demo_polish_closeout_2026-05-20\.md$|^$" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T08 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T08 (closeout $LINES 行,7 段齐)"
