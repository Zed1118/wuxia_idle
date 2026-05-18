#!/bin/bash
# T01 verify · PROGRESS.md 96 行清理 → < 80
set -uo pipefail
TARGET="PROGRESS.md"
test -f "$TARGET" || { echo "VERIFY FAIL: $TARGET missing"; exit 1; }

# 1. 行数 < 80
LINES=$(wc -l < "$TARGET" | tr -d ' ')
if [ "$LINES" -ge 80 ]; then
  echo "VERIFY FAIL: PROGRESS.md $LINES 行(目标 < 80)"
  exit 1
fi

# 2. 关键挂账 # 仍存
for hashtag in "#37" "#43" "#44"; do
  grep -q "$hashtag" "$TARGET" || { echo "VERIFY FAIL: 挂账 $hashtag 丢失"; exit 1; }
done
# 3. 已销账标记 ✅ 仍存
for done_marker in "#38" "#40" "#41" "#42"; do
  grep -q "$done_marker" "$TARGET" || { echo "VERIFY FAIL: 已销账 $done_marker 标记丢失"; exit 1; }
done

# 4. 顶段「当前阶段」仍有内容
grep -q "## 当前阶段" "$TARGET" || { echo "VERIFY FAIL: 顶段标题丢失"; exit 1; }
# 5. 归档段「### W17-W18 详条迁出」已新增
grep -q "W17-W18 详条迁出" "$TARGET" || { echo "VERIFY FAIL: W17-W18 归档段未新增"; exit 1; }

# 6. commit message check
git log -1 --pretty=%s | grep -q "nightshift T01" || { echo "VERIFY FAIL: no nightshift T01 commit"; exit 1; }

echo "VERIFY PASS: T01 (PROGRESS.md $LINES 行)"
