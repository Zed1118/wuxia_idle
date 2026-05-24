#!/bin/bash
# T14 verify · P3.4 sect_event Batch 2.2 service

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T14"

# === 1. path_guard 白名单 ===
verify_path_guard "lib/features/sect/.+\.dart|lib/core/game_loop/.+\.dart|test/features/sect/.+\.dart|pubspec\.lock"

# === 2. diff 真改了关键文件 ===
verify_diff_contains "lib/features/sect/application/sect_event_service\.dart" "lib/features/sect/application/sect_reputation_decay\.dart" "lib/core/game_loop/monthly_tick\.dart" "test/features/sect/.+_test\.dart"

# === 3. SectEventService 真实装 checkAndTrigger + resolve ===
if ! grep -qE "class SectEventService" lib/features/sect/application/sect_event_service.dart; then
  verify_fail "SectEventService class 缺"
fi
if ! grep -qE "SectEvent\? checkAndTrigger" lib/features/sect/application/sect_event_service.dart; then
  verify_fail "SectEventService.checkAndTrigger method 缺(签名 SectEvent? returns)"
fi
if ! grep -qE "resolve\(\{|resolve\(" lib/features/sect/application/sect_event_service.dart; then
  verify_fail "SectEventService.resolve method 缺"
fi

# === 4. 链路语义:cooldown / 境界 / activeEventsMax / triggerProbability 都消费 ===
for kw in "cooldown_days" "trigger_realm_min" "active_events_max" "trigger_probability"; do
  if ! grep -qE "$kw" lib/features/sect/application/sect_event_service.dart; then
    verify_fail "SectEventService 缺 spec §4 链路 key '$kw'"
  fi
done

# === 5. resolve clamp 红线(reputation/sectLevel 不越界) ===
if ! grep -qE "\.clamp\(" lib/features/sect/application/sect_event_service.dart; then
  verify_fail "resolve 缺 .clamp() 数值红线保护"
fi

# === 6. SectReputationDecayService computeDecay 纯函数 ===
if ! grep -qE "class SectReputationDecayService" lib/features/sect/application/sect_reputation_decay.dart; then
  verify_fail "SectReputationDecayService class 缺"
fi
if ! grep -qE "computeDecay" lib/features/sect/application/sect_reputation_decay.dart; then
  verify_fail "computeDecay method 缺"
fi

# === 7. MonthlyTickCoordinator infra 起 ===
if ! grep -qE "class MonthlyTickCoordinator" lib/core/game_loop/monthly_tick.dart; then
  verify_fail "MonthlyTickCoordinator class 缺"
fi

# === 8. 不动 numbers_config.dart 强类型化(diff 应 0 改) ===
if git diff main..HEAD --name-only | grep -qE "^lib/data/numbers_config\.dart$"; then
  verify_fail "本 task 不应改 numbers_config.dart(用 raw map 取值避撞 conflict)"
fi

# === 9. flutter build_runner + analyze ===
verify_build_runner_strict
verify_analyze_clean

# === 10. R5 测族通过 ===
verify_local_tests "test/features/sect/sect_event_service_test.dart" "test/features/sect/sect_reputation_decay_test.dart"

# === 11. commit message ===
verify_commit_message "nightshift T14"

verify_done
