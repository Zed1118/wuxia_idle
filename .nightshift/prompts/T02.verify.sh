#!/bin/bash
# T02 verify v2 · BreakthroughBlocker 集成 character_panel
# v2 修补(2026-05-24): A2 路径不写死,改 verify_diff_contains
set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T02"

# === 1. path_guard 宽松版(允许 character_panel 真目录) ===
verify_path_guard "lib/features/(character|character_panel)/.+\.dart|test/features/(character|character_panel)/.+\.dart"

# === 2. diff 真改了 character_panel 相关文件(不写死路径) ===
verify_diff_contains "character_panel.*\.dart"

# === 3. diff 中至少有 1 行新增 BreakthroughBlocker 引用 ===
if ! git diff HEAD~1 HEAD | grep -qE "^\+.*BreakthroughBlocker"; then
  verify_fail "diff 未含新增 BreakthroughBlocker 引用"
fi

# === 4. diff 中接 mainlineProgressProvider ===
if ! git diff HEAD~1 HEAD | grep -qE "^\+.*mainlineProgress|clearedStageIds"; then
  verify_fail "diff 未含 mainlineProgress / clearedStageIds(集成 reactive provider)"
fi

# === 5. flutter prerun + analyze ===
verify_build_runner_strict
verify_analyze_clean

# === 6. inner_demon test 不破(关键守护) ===
if ls test/features/inner_demon/ >/dev/null 2>&1; then
  flutter test test/features/inner_demon/ >> "$TASK_LOG" 2>&1 || verify_fail "test/features/inner_demon 不通过"
fi

# === 7. commit message ===
verify_commit_message "nightshift T02"

verify_done
