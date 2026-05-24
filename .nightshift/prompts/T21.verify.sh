#!/bin/bash
# T21 verify · P4.1 §12.2 帮派门派 Phase 0 + spec 起草

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T21"

# === 1. path_guard 白名单 ===
verify_path_guard "docs/phase0/p4_1_sect_management_phase0_.+\.md|docs/spec/p4_1_sect_management_spec_.+\.md|pubspec\.lock"

# === 2. Phase 0 doc 存在 + 关键段 ===
phase0_doc=$(ls docs/phase0/p4_1_sect_management_phase0_*.md 2>/dev/null | head -1)
if [ -z "$phase0_doc" ]; then
  verify_fail "Phase 0 doc 缺"
fi
phase0_lines=$(wc -l < "$phase0_doc")
if [ "$phase0_lines" -gt 100 ]; then
  verify_fail "Phase 0 doc $phase0_lines 行超 100 上限"
fi
# 关键段 grep
for kw in "schema" "caller" "邻近" "UI" "红线" "公式"; do
  if ! grep -qE "$kw" "$phase0_doc"; then
    verify_fail "Phase 0 doc 缺 6 维之一 '$kw'"
  fi
done
# Q1-Q8 表
for q in "Q1" "Q5" "Q8"; do
  if ! grep -qE "\b$q\b" "$phase0_doc"; then
    verify_fail "Phase 0 doc 缺候选 $q"
  fi
done

# === 3. spec doc 存在 + ≤150 行 ===
spec_doc=$(ls docs/spec/p4_1_sect_management_spec_*.md 2>/dev/null | head -1)
if [ -z "$spec_doc" ]; then
  verify_fail "spec doc 缺"
fi
spec_lines=$(wc -l < "$spec_doc")
if [ "$spec_lines" -gt 200 ]; then
  verify_fail "spec doc $spec_lines 行超 200(目标 ≤150)"
fi

# === 4. spec doc 关键段(8-9 章节)===
for kw in "范围" "schema" "service" "UI" "Batch" "估时"; do
  if ! grep -qE "$kw" "$spec_doc"; then
    verify_fail "spec doc 缺关键段 '$kw'"
  fi
done

# === 5. 0 lib/data 改动(本 task 纯 spec)===
changed=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null)
if echo "$changed" | grep -qE "^lib/|^data/|^test/"; then
  echo "  改动文件清单:"
  echo "$changed" | head -10
  verify_fail "T21 spec task 不应改 lib/data/test · 真改了"
fi

# === 6. commit message ===
verify_commit_message "nightshift T21"

verify_done
