#!/bin/bash
# T08 verify · SUMMARY 生成
set -e
SUM_FILE=".nightshift/SUMMARY.md"
test -f "$SUM_FILE" || { echo "VERIFY FAIL: $SUM_FILE missing"; exit 1; }
grep -q "Nightshift SUMMARY" "$SUM_FILE" || { echo "VERIFY FAIL: missing title"; exit 1; }
grep -q "## 1. 任务执行状态" "$SUM_FILE" || { echo "VERIFY FAIL: missing section 1"; exit 1; }
grep -q "## 4. 早上 review 清单" "$SUM_FILE" || { echo "VERIFY FAIL: missing review section"; exit 1; }
grep -q "## 5. 已知偏差" "$SUM_FILE" || { echo "VERIFY FAIL: missing follow-up section"; exit 1; }
grep -q "## 7. 启动到结束时间" "$SUM_FILE" || { echo "VERIFY FAIL: missing timing section"; exit 1; }
git log -1 --pretty=%s | grep -q "nightshift T08" || { echo "VERIFY FAIL: no nightshift T08 commit"; exit 1; }
echo "VERIFY PASS: T08"
