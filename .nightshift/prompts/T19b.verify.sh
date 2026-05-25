#!/bin/bash
# T19b verify · 技术债 3 合一(numbers_config 强类型 + sect Isar 持久化 + systemClock)

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T19b"

# === 1. path_guard 白名单 ===
verify_path_guard "lib/data/numbers_config\.dart|lib/data/isar_setup\.dart|lib/features/pvp/application/.+\.dart|lib/features/sect/application/.+\.dart|lib/features/sect/presentation/sect_screen\.dart|lib/features/sect/presentation/widgets/sect_event_dialog\.dart|lib/core/application/system_clock_provider\.dart|lib/core/application/system_clock_provider\.g\.dart|test/data/numbers_config_.+\.dart|test/features/(pvp|sect)/.+\.dart|test/core/application/system_clock_provider_test\.dart|docs/handoff/p3_tech_debt_closeout_.+\.md|pubspec\.lock"

# === 2. PvpDef 强类型 ===
if ! grep -qE "class PvpDef" lib/data/numbers_config.dart; then
  verify_fail "numbers_config.dart 缺 PvpDef class"
fi
if ! grep -qE "class SectEventDef" lib/data/numbers_config.dart; then
  verify_fail "numbers_config.dart 缺 SectEventDef class"
fi
if ! grep -qE "PvpDef\s+pvp\b|final\s+PvpDef\s+pvp" lib/data/numbers_config.dart; then
  verify_fail "NumbersConfig 缺 PvpDef pvp 字段"
fi
if ! grep -qE "SectEventDef\s+sectEvent\b|final\s+SectEventDef\s+sectEvent" lib/data/numbers_config.dart; then
  verify_fail "NumbersConfig 缺 SectEventDef sectEvent 字段"
fi

# === 3. pvp_service 切到强类型(删 raw map) ===
if grep -qE "numbers\.raw\['pvp'\]" lib/features/pvp/application/pvp_service.dart; then
  verify_fail "pvp_service 仍用 numbers.raw['pvp'] 未切强类型"
fi

# === 4. sect_event_service 切到强类型 ===
if grep -qE "numbers\.raw\['sect_event'\]" lib/features/sect/application/sect_event_service.dart; then
  verify_fail "sect_event_service 仍用 numbers.raw['sect_event'] 未切强类型"
fi

# === 5. isar_setup 加 4 schema + saveVersion 升 ===
for schema in SectSchema SectEventSchema PvpRecordSchema PvpSnapshotSchema; do
  if ! grep -qE "\b$schema\b" lib/data/isar_setup.dart; then
    verify_fail "isar_setup.dart 缺 $schema"
  fi
done
# saveVersion 应是 0.13.0 或 0.14.0(T17 升 0.13.0 + T19 升 0.14.0)
sv=$(grep -oE "_currentSaveVersion = '[0-9]+\.[0-9]+\.[0-9]+'" lib/data/isar_setup.dart | head -1)
if [ -z "$sv" ]; then
  verify_fail "isar_setup.dart 缺 _currentSaveVersion"
fi

# === 6. sect_providers 改 StreamProvider + AsyncNotifier ===
if grep -qE "extends Notifier<SectState>" lib/features/sect/application/sect_providers.dart; then
  verify_fail "sect_providers 仍用 SectStateNotifier extends Notifier<SectState>(内存 state) · 应切 StreamProvider/AsyncNotifier"
fi
if ! grep -qE "StreamProvider|StreamNotifier|@riverpod" lib/features/sect/application/sect_providers.dart; then
  verify_fail "sect_providers 缺 StreamProvider/AsyncNotifier 真持久化体例"
fi

# === 7. systemClockProvider 新 ===
verify_file_exists "lib/core/application/system_clock_provider.dart"
if ! grep -qE "class SystemClock|systemClockProvider" lib/core/application/system_clock_provider.dart; then
  verify_fail "system_clock_provider.dart 缺 SystemClock 类 / systemClockProvider"
fi

# === 8. closeout doc ≤100 行 ===
closeout_file=$(ls docs/handoff/p3_tech_debt_closeout_*.md 2>/dev/null | head -1)
if [ -z "$closeout_file" ]; then
  verify_fail "closeout doc 缺"
fi
closeout_lines=$(wc -l < "$closeout_file")
if [ "$closeout_lines" -gt 100 ]; then
  verify_fail "closeout doc $closeout_lines 行超 100 上限"
fi

# === 9. build_runner + analyze + 测试 ===
verify_build_runner_strict
verify_analyze_clean

# 现有 sect / pvp / main_menu 测族全过(0 行为变化守)
for f in test/features/pvp test/features/sect test/data; do
  if [ -d "$f" ]; then
    if ! flutter test "$f" >> "$TASK_LOG" 2>&1; then
      verify_fail "$f 测试不通过"
    fi
  fi
done

if [ -f test/core/application/system_clock_provider_test.dart ]; then
  verify_local_tests "test/core/application/system_clock_provider_test.dart"
fi

# === 10. commit message ===
verify_commit_message "nightshift T19b"

verify_done
