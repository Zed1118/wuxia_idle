#!/bin/bash
# T23 verify · 6 关键问题 5 小项合批修
source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T23"

# 1. path_guard 白名单
verify_path_guard "test/audit/cross_system_damage_test\.dart|data/lore/pvp/pvp_event_rank_up_yiLiu\.yaml|test/data/.+\.dart|test/features/(pvp|inheritance|jianghu)/.+\.dart|lib/data/numbers_config\.dart|data/numbers\.yaml|docs/spec/p4_1_sect_management_spec_2026-05-25\.md|docs/handoff/(6h_unattended_handoff|stage_audit_1_0_overall)_2026-05-25\.md"

# 2. T20 R5.8/R5.9 恒等断言修(不允许残留 1.25/1.15 硬编码)
if grep -nE "lessThanOrEqualTo\(1\.(25|15)\)" test/audit/cross_system_damage_test.dart 2>/dev/null; then
  verify_fail "T20 R5.8/R5.9 仍含 1.25/1.15 硬编码恒等"
fi

# 3. T18 narrative「听雨剑」字面删
if grep -q "听雨剑" data/lore/pvp/pvp_event_rank_up_yiLiu.yaml 2>/dev/null; then
  verify_fail "T18 rank_up_yiLiu 仍含「听雨剑」字面引用"
fi

# 4. T17 enemyAttackPowerMult 注释存在(简查 TODO 关键字附近)
if ! grep -B2 "enemyAttackPowerMult" lib/data/numbers_config.dart | grep -qE "TODO|占位|B3"; then
  verify_fail "lib/data/numbers_config.dart enemyAttackPowerMult 字段前未加 TODO 注释"
fi

# 5. T21 spec ≤150 行
spec="docs/spec/p4_1_sect_management_spec_2026-05-25.md"
if [ -f "$spec" ]; then
  lines=$(wc -l < "$spec" | tr -d ' ')
  if [ "$lines" -gt 150 ]; then
    verify_fail "$spec $lines 行超 150 上限"
  fi
fi

# 6. T22 SHA 替换:2 文件不含 4e79722
for f in docs/handoff/6h_unattended_handoff_2026-05-25.md docs/handoff/stage_audit_1_0_overall_2026-05-25.md; do
  if [ -f "$f" ] && grep -q "4e79722" "$f"; then
    verify_fail "$f 仍含 SHA 错 4e79722(应替 68c816d)"
  fi
done

# 7. closeout review 保留(史实不动)
if [ -f docs/handoff/session_closeout_2026-05-25_nightshift_6h_review.md ]; then
  if ! grep -q "4e79722" docs/handoff/session_closeout_2026-05-25_nightshift_6h_review.md; then
    verify_fail "closeout review SHA 史实被误删(行 63 周围应保留 4e79722)"
  fi
fi

# 8. analyze + 相关 test slice
verify_analyze_clean
verify_local_tests test/audit/cross_system_damage_test.dart

# 9. commit message
verify_commit_message "nightshift T23"

verify_done
