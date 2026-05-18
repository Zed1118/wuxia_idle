#!/bin/bash
# T09 verify · lib/ 目录结构审计
set -uo pipefail
TARGET="docs/handoff/lib_structure_audit_2026-05-19.md"
test -f "$TARGET" || { echo "VERIFY FAIL: $TARGET missing"; exit 1; }

# 1. 行数 ≤ 80 + 20% buffer
LINES=$(wc -l < "$TARGET" | tr -d ' ')
if [ "$LINES" -gt 96 ]; then
  echo "VERIFY FAIL: audit md $LINES 行 > 96 严重超 80"
  exit 1
fi

# 2. 4 段结构齐
for section in "§1" "§2" "§3" "§4"; do
  grep -q "$section" "$TARGET" || { echo "VERIFY FAIL: 段 '$section' 缺"; exit 1; }
done

# 3. 关键 feature 提及(本会话新加)
for feature in "tutorial" "codex"; do
  grep -q "$feature" "$TARGET" || { echo "VERIFY FAIL: 新 feature $feature 未审"; exit 1; }
done

# 4. commit message check
git log -1 --pretty=%s | grep -q "nightshift T09" || { echo "VERIFY FAIL: no nightshift T09 commit"; exit 1; }

# 5. 仅 docs/handoff/ 改动
CHANGED_OUTSIDE=$(git show --name-only HEAD | grep -vE "^commit|^Author|^Date|^docs/handoff/|^$|^docs\(nightshift" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T09 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T09 (audit md $LINES 行)"
