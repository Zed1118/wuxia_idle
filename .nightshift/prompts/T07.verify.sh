#!/bin/bash
# T07 verify · typedef/extension 死字段周期审计
set -uo pipefail
TARGET="docs/handoff/typedef_extension_audit_2026-05-19.md"
test -f "$TARGET" || { echo "VERIFY FAIL: $TARGET missing"; exit 1; }

# 1. 行数 ≤ 100 + 20% buffer
LINES=$(wc -l < "$TARGET" | tr -d ' ')
if [ "$LINES" -gt 120 ]; then
  echo "VERIFY FAIL: audit md $LINES 行 > 120 严重超 100"
  exit 1
fi

# 2. 4 段结构齐
for section in "§1" "§2" "§3" "§4"; do
  grep -q "$section" "$TARGET" || { echo "VERIFY FAIL: 段 '$section' 缺"; exit 1; }
done

# 3. 关键 keyword
grep -qE "Extension|extension" "$TARGET" || { echo "VERIFY FAIL: extension 关键词缺"; exit 1; }
grep -qE "lib/data/defs|def file" "$TARGET" || { echo "VERIFY FAIL: defs 段缺"; exit 1; }

# 4. commit message check
git log -1 --pretty=%s | grep -q "nightshift T07" || { echo "VERIFY FAIL: no nightshift T07 commit"; exit 1; }

# 5. 仅 docs/handoff/ 改动
CHANGED_OUTSIDE=$(git show --name-only HEAD | grep -vE "^commit|^Author|^Date|^docs/handoff/|^$|^docs\(nightshift" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T07 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T07 (audit md $LINES 行)"
