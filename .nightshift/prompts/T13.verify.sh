#!/bin/bash
# T13 verify · P3.3 PVP Phase 3 logic

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T13"

# === 1. path_guard 白名单 ===
verify_path_guard "lib/features/pvp/.+\.dart|test/features/pvp/.+\.dart|pubspec\.lock"

# === 2. diff 真改了关键文件 ===
verify_diff_contains "lib/features/pvp/domain/strategy/pvp_strategy\.dart" "lib/features/pvp/application/pvp_sync_service\.dart" "lib/features/pvp/application/pvp_service\.dart" "test/features/pvp/.+_test\.dart"

# === 3. PvpStrategy 真 implements BattleStrategy + 组合委派 ===
if ! grep -qE "class PvpStrategy implements BattleStrategy" lib/features/pvp/domain/strategy/pvp_strategy.dart; then
  verify_fail "PvpStrategy 缺 implements BattleStrategy"
fi
if ! grep -qE "DefaultGroundStrategy" lib/features/pvp/domain/strategy/pvp_strategy.dart; then
  verify_fail "PvpStrategy 缺 DefaultGroundStrategy 组合委派"
fi

# === 4. 数值红线:不引入 attackPowerMultiplier ===
if grep -qE "attackPowerMultiplier" lib/features/pvp/domain/strategy/pvp_strategy.dart; then
  verify_fail "§5.4 红线违反:PvpStrategy 引入 attackPowerMultiplier ELO buff 越权"
fi

# === 5. NoopPvpSync 真实装 + abstract PvpSyncService ===
if ! grep -qE "abstract class PvpSyncService" lib/features/pvp/application/pvp_sync_service.dart; then
  verify_fail "PvpSyncService abstract 缺"
fi
if ! grep -qE "class NoopPvpSync implements PvpSyncService" lib/features/pvp/application/pvp_sync_service.dart; then
  verify_fail "NoopPvpSync implements PvpSyncService 缺"
fi

# === 6. ELO 纯函数 ===
if ! grep -qE "expectedScore|eloDelta" lib/features/pvp/application/pvp_elo.dart 2>/dev/null && \
   ! grep -qE "expectedScore|eloDelta" lib/features/pvp/application/pvp_service.dart 2>/dev/null; then
  verify_fail "ELO calc(expectedScore / eloDelta)缺"
fi

# === 7. flutter build_runner + analyze ===
verify_build_runner_strict
verify_analyze_clean

# === 8. R5 测族通过 ===
verify_local_tests "test/features/pvp/pvp_strategy_test.dart" "test/features/pvp/pvp_service_test.dart"

# === 9. commit message ===
verify_commit_message "nightshift T13"

verify_done
