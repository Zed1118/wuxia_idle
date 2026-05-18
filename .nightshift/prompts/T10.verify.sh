#!/bin/bash
# T10 verify · SUMMARY 生成
set -uo pipefail
TARGET=".nightshift/SUMMARY.md"
test -f "$TARGET" || { echo "VERIFY FAIL: $TARGET missing"; exit 1; }

# 1. 行数合理(50-200)
LINES=$(wc -l < "$TARGET" | tr -d ' ')
if [ "$LINES" -lt 50 ]; then
  echo "VERIFY FAIL: SUMMARY $LINES 行 < 50 太短"
  exit 1
fi
if [ "$LINES" -gt 250 ]; then
  echo "VERIFY FAIL: SUMMARY $LINES 行 > 250 太长"
  exit 1
fi

# 2. 7 段结构齐
for section in "1. 任务执行状态" "2. Git commits" "3. 测试" "4. 早上 review" "5. 已知偏差" "6. dispatcher 健壮性" "7. 启动到结束时间"; do
  grep -q "$section" "$TARGET" || { echo "VERIFY FAIL: 段 '$section' 缺"; exit 1; }
done

# 3. 10 task 全提及
for t in T01 T02 T03 T04 T05 T06 T07 T08 T09 T10; do
  grep -q "$t" "$TARGET" || { echo "VERIFY FAIL: $t 未提"; exit 1; }
done

# 4. commit message check
git log -1 --pretty=%s | grep -q "nightshift T10" || { echo "VERIFY FAIL: no nightshift T10 commit"; exit 1; }

# 5. 仅 .nightshift/ 改动
CHANGED_OUTSIDE=$(git show --name-only HEAD | grep -vE "^commit|^Author|^Date|^\.nightshift/|^$|^docs\(nightshift" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T10 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T10 (SUMMARY $LINES 行)"
