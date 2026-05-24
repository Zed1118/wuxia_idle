#!/bin/bash
# T11 verify · P3.3 PVP Phase 2 schema
# v2 体例:path_guard + diff_contains + section keyword + flutter build_runner/analyze/test + commit msg

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T11"

# === 1. path_guard 白名单(diff 越界 → fail_scope) ===
verify_path_guard "lib/features/pvp/.+\.dart|lib/core/domain/enums\.dart|data/numbers\.yaml|test/features/pvp/.+\.dart|pubspec\.lock"

# === 2. diff 真改了关键 4 文件类型 ===
verify_diff_contains "lib/features/pvp/domain/pvp_record\.dart" "lib/features/pvp/domain/pvp_snapshot\.dart" "lib/core/domain/enums\.dart" "data/numbers\.yaml" "test/features/pvp/.+_test\.dart"

# === 3. enum StageType 真加了 pvp 第 6 项 ===
if ! git diff main..HEAD -- lib/core/domain/enums.dart | grep -qE "^\+.*pvp,"; then
  verify_fail "diff 未含 enum StageType 加 pvp(查 ^\+.*pvp,)"
fi

# === 4. numbers.yaml 加了 pvp: 段 ===
if ! grep -qE "^pvp:" data/numbers.yaml; then
  verify_fail "data/numbers.yaml 缺 pvp: 段"
fi
if ! grep -qE "^  elo:" data/numbers.yaml; then
  verify_fail "numbers.yaml pvp.elo 子段缺"
fi
if ! grep -qE "k_factor: 32" data/numbers.yaml; then
  verify_fail "numbers.yaml pvp.elo.k_factor=32 缺"
fi

# === 5. PvpRecord composite index 真写了 ===
if ! grep -qE "CompositeIndex\('timestamp'\)" lib/features/pvp/domain/pvp_record.dart; then
  verify_fail "PvpRecord 缺 composite index (timestamp)"
fi

# === 6. flutter build_runner + analyze ===
verify_build_runner_strict
verify_analyze_clean

# === 7. g.dart 真生成 ===
if [ ! -f lib/features/pvp/domain/pvp_record.g.dart ]; then
  verify_fail "pvp_record.g.dart 未生成(build_runner 未拣到 @Collection)"
fi
if [ ! -f lib/features/pvp/domain/pvp_snapshot.g.dart ]; then
  verify_fail "pvp_snapshot.g.dart 未生成"
fi

# === 8. R5 schema 测族通过 ===
verify_local_tests "test/features/pvp/pvp_schema_test.dart"

# === 9. commit message ===
verify_commit_message "nightshift T11"

verify_done
