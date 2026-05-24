#!/bin/bash
# T05 verify v2 · P3.3 PVP Phase 1 spec
# v2 修补(2026-05-24): A4 不 grep §N,改 verify_section_titles
set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T05"

DOC="docs/spec/p3_3_pvp_spec_2026-05-24.md"

# === 1. 文件存在 ===
verify_file_exists "$DOC"

# === 2. path_guard ===
verify_path_guard "docs/spec/p3_3_pvp_spec_2026-05-24\.md"

# === 3. 9 节标题文字(T05 用 R5 测族 体例不是 测试 字面) ===
verify_section_titles "$DOC" "范围" "schema" "yaml" "行为" "UI" "narrative" "R5" "Batch" "风险"

# === 4. Q1-Q5 决议引述 ===
for q in Q1 Q2 Q3 Q4 Q5; do
  grep -q "$q" "$DOC" || verify_fail "$q 决议引述 missing"
done

# === 5. PvpRecord schema 类名 ===
grep -q "PvpRecord" "$DOC" || verify_fail "PvpRecord 类名 missing"

# === 6. 关键设计点 ===
grep -q "离线快照\|snapshot" "$DOC" || verify_fail "离线快照设计点 missing"
grep -q "BattleStrategy" "$DOC" || verify_fail "BattleStrategy 复用提及 missing"

# === 7. 体量 100-180 行 ===
LINES=$(wc -l < "$DOC")
if [ "$LINES" -lt 100 ] || [ "$LINES" -gt 180 ]; then
  verify_fail "spec 体量 $LINES 行越界(应 100-180)"
fi
echo "  spec lines: $LINES (100-180 OK)"

# === 8. commit message ===
verify_commit_message "nightshift T05"

verify_done
