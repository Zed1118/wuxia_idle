#!/bin/bash
# T24 verify · EncounterIntegration 真 wire(caller 端注入 ReputationDeltaApplier)
source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T24"

# 1. path_guard 白名单(若 Phase 0 发现需补 ref 链,lib/features 其他文件可能 SCOPE_OUT,
#    那时人工 review · 不放宽默认)
verify_path_guard "lib/features/encounter/presentation/encounter_hook\.dart|lib/features/debug/presentation/encounter_debug_picker\.dart|lib/features/jianghu/application/reputation_service\.dart|test/features/encounter/encounter_reputation_wire_test\.dart|lib/features/.+\.dart"

# 2. encounter_hook.dart caller 真传 reputationApplier
if ! grep -E "reputationApplier:\s*\S" lib/features/encounter/presentation/encounter_hook.dart >/dev/null 2>&1; then
  verify_fail "encounter_hook.dart caller 漏传 reputationApplier 参数"
fi

# 3. encounter_debug_picker.dart caller 真传 reputationApplier
if ! grep -E "reputationApplier:\s*\S" lib/features/debug/presentation/encounter_debug_picker.dart >/dev/null 2>&1; then
  verify_fail "encounter_debug_picker.dart caller 漏传 reputationApplier 参数"
fi

# 4. ReputationService 加 deltaApplierFromRng helper
verify_grep_safe lib/features/jianghu/application/reputation_service.dart "deltaApplierFromRng" "ReputationService helper deltaApplierFromRng"

# 5. test 文件存在 + 含 3 测族关键字
test_file="test/features/encounter/encounter_reputation_wire_test.dart"
verify_file_exists "$test_file"
# 3 测族关键字:真触发 / null 兼容 / 范围抽样
for kw in "applyDelta" "reputationApplier" "deltaMin\|deltaMax"; do
  if ! grep -qE "$kw" "$test_file"; then
    verify_warn "$test_file 未含关键字 '$kw' · 测族覆盖可能漏"
  fi
done

# 6. EncounterService.dart 未被改(service 端不动)
if git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null | grep -q "lib/features/encounter/application/encounter_service.dart"; then
  verify_fail "禁区 lib/features/encounter/application/encounter_service.dart 被改"
fi

# 7. analyze + 相关 test slice
verify_analyze_clean
verify_local_tests "$test_file"
# 兼容 reputation_service test(若 helper 改了签名要看影响)
if [ -f test/features/jianghu/reputation_service_test.dart ]; then
  verify_local_tests test/features/jianghu/reputation_service_test.dart
fi

# 8. commit message
verify_commit_message "nightshift T24"

verify_done
