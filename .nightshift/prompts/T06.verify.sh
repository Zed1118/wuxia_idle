#!/bin/bash
# T06 verify · nightshift SUMMARY 二次跑
# Verify in worktree cwd (relative path), since T06 writes to worktree-local .nightshift/SUMMARY.md
set -e
SUMMARY=".nightshift/SUMMARY.md"
test -f "$SUMMARY" || { echo "VERIFY FAIL: $SUMMARY missing in worktree"; exit 1; }
grep -q "任务执行状态" "$SUMMARY" || { echo "VERIFY FAIL: missing task status section"; exit 1; }
grep -q "Git commits" "$SUMMARY" || { echo "VERIFY FAIL: missing git commits section"; exit 1; }
grep -q "早上 review" "$SUMMARY" || { echo "VERIFY FAIL: missing review checklist"; exit 1; }
grep -q "dispatcher 健壮性\|健壮性验证" "$SUMMARY" || { echo "VERIFY FAIL: missing dispatcher robustness verification section"; exit 1; }
git log -1 --pretty=%s | grep -q "nightshift T06" || { echo "VERIFY FAIL: no nightshift T06 commit"; exit 1; }
echo "VERIFY PASS: T06"
