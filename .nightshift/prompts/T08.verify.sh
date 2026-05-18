#!/bin/bash
# T08 verify · 死代码 dry-run scan
set -uo pipefail
TARGET="docs/handoff/deadcode_scan_2026-05-19.md"
test -f "$TARGET" || { echo "VERIFY FAIL: $TARGET missing"; exit 1; }

# 1. 行数 ≤ 100 + 20% buffer
LINES=$(wc -l < "$TARGET" | tr -d ' ')
if [ "$LINES" -gt 120 ]; then
  echo "VERIFY FAIL: scan md $LINES 行 > 120 严重超 100"
  exit 1
fi

# 2. 4 段结构齐
for section in "§1" "§2" "§3" "§4"; do
  grep -q "$section" "$TARGET" || { echo "VERIFY FAIL: 段 '$section' 缺"; exit 1; }
done

# 3. 关键 keyword
grep -qE "dart fix|dry.?run" "$TARGET" || { echo "VERIFY FAIL: dart fix dry-run 关键词缺"; exit 1; }
grep -qE "provider|@riverpod" "$TARGET" || { echo "VERIFY FAIL: provider 段缺"; exit 1; }

# 4. lib/ 未被改动(钉死 dry-run)
CHANGED_LIB=$(git show --name-only HEAD | grep "^lib/" || true)
if [ -n "$CHANGED_LIB" ]; then
  echo "VERIFY FAIL: T08 改动 lib/ 违反 dry-run 钉死红线:"
  echo "$CHANGED_LIB"
  exit 1
fi

# 5. commit message check
git log -1 --pretty=%s | grep -q "nightshift T08" || { echo "VERIFY FAIL: no nightshift T08 commit"; exit 1; }

# 6. 仅 docs/handoff/ 改动
CHANGED_OUTSIDE=$(git show --name-only HEAD | grep -vE "^commit|^Author|^Date|^docs/handoff/|^$|^docs\(nightshift" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T08 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T08 (scan md $LINES 行)"
