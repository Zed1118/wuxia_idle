#!/bin/bash
# T04 verify · PROGRESS.md 行数清理
set -e
test -f "PROGRESS.md" || { echo "VERIFY FAIL: PROGRESS.md missing"; exit 1; }
LINES=$(wc -l < PROGRESS.md | tr -d ' ')
echo "PROGRESS.md lines: $LINES"
[ "$LINES" -lt 80 ] || { echo "VERIFY FAIL: PROGRESS.md $LINES lines >= 80, target < 80"; exit 1; }
# Anchor sections must remain
grep -q "## 当前阶段" PROGRESS.md || { echo "VERIFY FAIL: missing 当前阶段 section"; exit 1; }
grep -q "## 下一步" PROGRESS.md || { echo "VERIFY FAIL: missing 下一步 section"; exit 1; }
grep -q "## 关键约束" PROGRESS.md || { echo "VERIFY FAIL: missing 关键约束 section"; exit 1; }
grep -q "## 远程仓库" PROGRESS.md || { echo "VERIFY FAIL: missing 远程仓库 section"; exit 1; }
grep -q "## 归档" PROGRESS.md || { echo "VERIFY FAIL: missing 归档 section"; exit 1; }
# Latest anchor must remain (W17 nightshift + T03 follow-up commit fc25207)
grep -q "fc25207\|T03 follow-up\|nightshift" PROGRESS.md || { echo "VERIFY FAIL: missing W17 nightshift / T03 follow-up anchor"; exit 1; }
git log -1 --pretty=%s | grep -q "nightshift T04" || { echo "VERIFY FAIL: no nightshift T04 commit"; exit 1; }
# Project still healthy (no lib changes per scope)
flutter pub get >/dev/null 2>&1
dart run build_runner build >/dev/null 2>&1 || { echo "VERIFY WARN: build_runner non-zero, continuing"; }
flutter analyze --fatal-infos >/dev/null 2>&1 || { echo "VERIFY FAIL: dart analyze"; exit 1; }
echo "VERIFY PASS: T04 (lines: $LINES)"
