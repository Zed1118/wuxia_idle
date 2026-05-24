#!/bin/bash
# T20 verify · 跨系统数值红线压测 audit

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T20"

# === 1. path_guard 白名单 ===
verify_path_guard "docs/audit/cross_system_damage_audit_.+\.md|test/audit/cross_system_damage_test\.dart|pubspec\.lock"

# === 2. audit doc 存在 + ≤100 行 ===
audit_doc=$(ls docs/audit/cross_system_damage_audit_*.md 2>/dev/null | head -1)
if [ -z "$audit_doc" ]; then
  verify_fail "audit doc 缺"
fi
audit_lines=$(wc -l < "$audit_doc")
if [ "$audit_lines" -gt 100 ]; then
  verify_fail "audit doc $audit_lines 行超 100 上限(目标 ≤80)"
fi

# === 3. audit doc 关键段(§1 接入点 + §2 叠加 + §4 R5 + §5 结论)===
for section_kw in "接入点" "叠加" "R5" "结论"; do
  if ! grep -qE "$section_kw" "$audit_doc"; then
    verify_fail "audit doc 缺关键段 '$section_kw'"
  fi
done

# === 4. R5 测族文件存在 + 6+ 测 ===
verify_file_exists "test/audit/cross_system_damage_test.dart"
test_count=$(grep -cE "^\s*test\(" test/audit/cross_system_damage_test.dart || echo 0)
if [ "$test_count" -lt 6 ]; then
  verify_fail "R5 跨系统测族 $test_count < 6(目标 6-10)"
fi

# === 5. 关键测覆盖 ===
for kw in "lessThanOrEqualTo(8000)" "attackPowerMultiplier" "baseline\|普攻\|普伤"; do
  if ! grep -qE "$kw" test/audit/cross_system_damage_test.dart; then
    verify_fail "R5 测族缺关键约束/逻辑 '$kw'"
  fi
done

# === 6. flutter analyze + 跑 R5 测 ===
verify_analyze_clean
verify_local_tests "test/audit/cross_system_damage_test.dart"

# === 7. commit message ===
verify_commit_message "nightshift T20"

verify_done
