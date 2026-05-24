#!/bin/bash
# T04 verify v2 · P3.4 门派事件 Phase 1 spec
# v2 修补(2026-05-24): A4 不 grep §N,改 verify_section_titles
set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T04"

DOC="docs/spec/p3_4_sect_event_spec_2026-05-24.md"

# === 1. 文件存在 ===
verify_file_exists "$DOC"

# === 2. path_guard ===
verify_path_guard "docs/spec/p3_4_sect_event_spec_2026-05-24\.md"

# === 3. 9 节标题文字(不查符号,查节标题文字,容忍 ## N. / ## §N / ### 等) ===
verify_section_titles "$DOC" "范围" "schema" "yaml" "行为" "UI" "narrative" "测试" "Batch" "风险"

# === 4. Q1-Q5 默认决议引述 ===
for q in Q1 Q2 Q3 Q4 Q5; do
  grep -q "$q" "$DOC" || verify_fail "$q 决议引述 missing"
done

# === 5. SectEvent schema 类名 ===
grep -q "SectEvent" "$DOC" || verify_fail "SectEvent 类名 missing"

# === 6. 体量 100-180 行 ===
LINES=$(wc -l < "$DOC")
if [ "$LINES" -lt 100 ] || [ "$LINES" -gt 180 ]; then
  verify_fail "spec 体量 $LINES 行越界(应 100-180)"
fi
echo "  spec lines: $LINES (100-180 OK)"

# === 7. commit message ===
verify_commit_message "nightshift T04"

verify_done
