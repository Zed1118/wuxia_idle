#!/bin/bash
# T12 verify · P3.4 sect_event Batch 2.1 schema

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T12"

# === 1. path_guard 白名单 ===
verify_path_guard "lib/features/sect/.+\.dart|data/numbers\.yaml|test/features/sect/.+\.dart|pubspec\.lock"

# === 2. diff 真改了关键 3 文件类型 ===
verify_diff_contains "lib/features/sect/domain/sect\.dart" "lib/features/sect/domain/sect_event\.dart" "data/numbers\.yaml" "test/features/sect/.+_test\.dart"

# === 3. Sect @Collection + 2 enum 真写了 ===
if ! grep -qE "^class Sect \{" lib/features/sect/domain/sect.dart; then
  verify_fail "Sect class 缺(lib/features/sect/domain/sect.dart)"
fi
if ! grep -qE "^enum SectEventType " lib/features/sect/domain/sect.dart; then
  verify_fail "SectEventType enum 缺(应放 sect.dart)"
fi
if ! grep -qE "^enum SectEventStatus " lib/features/sect/domain/sect.dart; then
  verify_fail "SectEventStatus enum 缺"
fi

# === 4. SectEvent composite index 真写了 ===
if ! grep -qE "CompositeIndex\('triggeredAt'\)" lib/features/sect/domain/sect_event.dart; then
  verify_fail "SectEvent 缺 composite index (sectId, triggeredAt)"
fi

# === 5. numbers.yaml 加了 sect_event: 段 ===
if ! grep -qE "^sect_event:" data/numbers.yaml; then
  verify_fail "data/numbers.yaml 缺 sect_event: 段"
fi
if ! grep -qE "trigger_probability: 0\.30" data/numbers.yaml; then
  verify_fail "sect_event.tournament.trigger_probability=0.30 缺"
fi
if ! grep -qE "promote_wins_threshold: 3" data/numbers.yaml; then
  verify_fail "sect_event.sect_level.promote_wins_threshold=3 缺"
fi

# === 6. 字段名隔离(不撞 P1.2 reputation)===
if ! grep -qE "late int sectReputation" lib/features/sect/domain/sect.dart; then
  verify_fail "Sect 字段名应是 sectReputation 不是 reputation(避撞 P1.2)"
fi

# === 7. flutter build_runner + analyze ===
verify_build_runner_strict
verify_analyze_clean

# === 8. g.dart 真生成 ===
if [ ! -f lib/features/sect/domain/sect.g.dart ]; then
  verify_fail "sect.g.dart 未生成"
fi
if [ ! -f lib/features/sect/domain/sect_event.g.dart ]; then
  verify_fail "sect_event.g.dart 未生成"
fi

# === 9. R5 schema 测族通过 ===
verify_local_tests "test/features/sect/sect_schema_test.dart"

# === 10. commit message ===
verify_commit_message "nightshift T12"

verify_done
