#!/bin/bash
# T15 verify · P3.3 PVP Phase 4 UI + Phase 5 narrative + closeout

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T15"

# === 1. path_guard 白名单 ===
verify_path_guard "lib/features/pvp/.+\.dart|lib/features/main_menu/presentation/main_menu\.dart|lib/shared/strings\.dart|data/lore/pvp/.+\.yaml|test/features/pvp/.+\.dart|test/features/main_menu/presentation/main_menu_test\.dart|docs/handoff/p3_3_pvp_full_closeout_.+\.md|pubspec\.lock"

# === 2. diff 真改了关键文件 ===
verify_diff_contains "lib/features/pvp/presentation/pvp_screen\.dart" "lib/features/main_menu/presentation/main_menu\.dart" "lib/shared/strings\.dart" "data/lore/pvp/.+\.yaml" "docs/handoff/p3_3_pvp_full_closeout_.+\.md"

# === 3. UiStrings 加了 mainMenuPvp ===
if ! grep -qE "mainMenuPvp\s*=" lib/shared/strings.dart; then
  verify_fail "UiStrings 缺 mainMenuPvp"
fi

# === 4. main_menu.dart 加了 PVP _MenuButton(用 mainMenuPvp 标志属性访问)===
if ! grep -qE "UiStrings\.mainMenuPvp" lib/features/main_menu/presentation/main_menu.dart; then
  verify_fail "main_menu.dart 缺 UiStrings.mainMenuPvp 引用"
fi

# === 5. PvpScreen 三态体例 ===
if ! grep -qE "class PvpScreen" lib/features/pvp/presentation/pvp_screen.dart; then
  verify_fail "PvpScreen class 缺"
fi
if ! grep -qE "stage_05_05" lib/features/pvp/presentation/pvp_screen.dart; then
  verify_fail "PvpScreen 缺 stage_05_05 unlock 校验"
fi

# === 6. narrative stub yaml ===
if [ ! -f data/lore/pvp/pvp_event_first_blood.yaml ]; then
  verify_fail "data/lore/pvp/pvp_event_first_blood.yaml stub 缺"
fi

# === 7. closeout doc 体量 ≤80 行(doc_inflation 上限)===
closeout_file=$(ls docs/handoff/p3_3_pvp_full_closeout_*.md 2>/dev/null | head -1)
if [ -z "$closeout_file" ]; then
  verify_fail "closeout doc 缺"
fi
closeout_lines=$(wc -l < "$closeout_file")
if [ "$closeout_lines" -gt 100 ]; then
  verify_fail "closeout doc $closeout_lines 行超 100(上限 80 + 容差 20)"
fi

# === 8. flutter build_runner + analyze ===
verify_build_runner_strict
verify_analyze_clean

# === 9. R4/R5 测族通过 ===
if [ -f test/features/pvp/pvp_screen_test.dart ]; then
  verify_local_tests "test/features/pvp/pvp_screen_test.dart"
fi

# === 10. main_menu test 全过(入口数适配)===
verify_local_tests "test/features/main_menu/presentation/main_menu_test.dart"

# === 11. commit message ===
verify_commit_message "nightshift T15"

verify_done
