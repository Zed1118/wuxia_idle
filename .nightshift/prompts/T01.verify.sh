#!/bin/bash
# T01 verify · P1.2 spec PR #6 4 项 minor fix
set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T01"

DOC="docs/spec/p1_2_jianghu_enmity_spec_2026-05-24.md"

# === 1. doc 存在(分支可能是 feat/p1_2_spec) ===
verify_file_exists "$DOC"

# === 2. path_guard: 只允许这个 spec doc ===
verify_path_guard "docs/spec/p1_2_jianghu_enmity_spec_2026-05-24\.md"

# === 3. 4 项 fix 都打到了 ===
grep -q "severe_threshold" "$DOC" || verify_fail "fix #1 severe_threshold missing"
grep -q "severe_mult" "$DOC" || verify_fail "fix #1 severe_mult missing"
grep -q "P3.2.C" "$DOC" || verify_fail "fix #2 P3.2.C 引用 missing"
# fix #3 schema-level 断言(Dart),只验文字含 schema/runtimeType 关键词
grep -E "schema|runtimeType|Collection" "$DOC" >/dev/null || verify_fail "fix #3 schema-level 断言文字 missing"
grep -E "composite|@Index" "$DOC" >/dev/null || verify_fail "fix #4 composite index missing"

# === 4. commit message ===
verify_commit_message "nightshift T01"

# === 5. 体量未爆(≤180 行,P1.2 原 144 行 + 4 项 fix 不该过 +40) ===
LINES=$(wc -l < "$DOC")
if [ "$LINES" -gt 180 ]; then
  verify_fail "spec 体量爆 $LINES > 180 行"
fi
echo "  spec lines: $LINES (≤180 OK)"

verify_done
