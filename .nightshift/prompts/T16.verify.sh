#!/bin/bash
# T16 verify · P3.4 sect_event Batch 2.3 + 2.4 + 2.5 收尾

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T16"

# === 1. path_guard 白名单 ===
verify_path_guard "lib/features/sect/.+\.dart|lib/features/main_menu/presentation/main_menu\.dart|lib/shared/strings\.dart|data/lore/sect_event/.+\.yaml|test/features/sect/.+\.dart|test/features/main_menu/presentation/main_menu_test\.dart|docs/handoff/p3_4_sect_event_full_closeout_.+\.md|pubspec\.lock"

# === 2. diff 真改了关键文件 ===
verify_diff_contains "lib/features/sect/presentation/sect_screen\.dart" "lib/features/main_menu/presentation/main_menu\.dart" "lib/shared/strings\.dart" "data/lore/sect_event/tournament_.+\.yaml" "docs/handoff/p3_4_sect_event_full_closeout_.+\.md"

# === 3. UiStrings 加了 mainMenuSect ===
if ! grep -qE "mainMenuSect\s*=" lib/shared/strings.dart; then
  verify_fail "UiStrings 缺 mainMenuSect"
fi

# === 4. main_menu.dart 加了 Sect _MenuButton ===
if ! grep -qE "UiStrings\.mainMenuSect" lib/features/main_menu/presentation/main_menu.dart; then
  verify_fail "main_menu.dart 缺 UiStrings.mainMenuSect 引用"
fi

# === 5. SectScreen + SectEventDialog 真新建 ===
if ! grep -qE "class SectScreen" lib/features/sect/presentation/sect_screen.dart; then
  verify_fail "SectScreen class 缺"
fi
if ! grep -qE "class SectEventDialog\|SectEventDialog" lib/features/sect/presentation/widgets/sect_event_dialog.dart 2>/dev/null; then
  verify_fail "SectEventDialog 缺(应在 widgets/ 子目录或 sect_screen 内)"
fi

# === 6. tournament narrative 2 条 ===
tournament_count=$(ls data/lore/sect_event/tournament_*.yaml 2>/dev/null | wc -l | tr -d ' ')
if [ "$tournament_count" -lt 2 ]; then
  verify_fail "tournament narrative 应 ≥ 2 条(实际 $tournament_count)"
fi

# === 7. 不引入新数值轴(SectEventDialog 复用 DefaultGroundStrategy 0 改 strategy) ===
if git diff main..HEAD --name-only | grep -qE "^lib/features/battle/domain/strategy/"; then
  verify_fail "本 task 不应改 lib/features/battle/domain/strategy/*(SectEventDialog 复用 DefaultGroundStrategy)"
fi

# === 8. closeout 体量 ≤100(80 + 容差 20)===
closeout_file=$(ls docs/handoff/p3_4_sect_event_full_closeout_*.md 2>/dev/null | head -1)
if [ -z "$closeout_file" ]; then
  verify_fail "closeout doc 缺"
fi
closeout_lines=$(wc -l < "$closeout_file")
if [ "$closeout_lines" -gt 100 ]; then
  verify_fail "closeout doc $closeout_lines 行超 100"
fi

# === 9. flutter build_runner + analyze ===
verify_build_runner_strict
verify_analyze_clean

# === 10. R4/R5 测族通过 ===
if [ -f test/features/sect/sect_screen_test.dart ]; then
  verify_local_tests "test/features/sect/sect_screen_test.dart"
fi
if [ -f test/features/sect/sect_battle_integration_test.dart ]; then
  verify_local_tests "test/features/sect/sect_battle_integration_test.dart"
fi

# === 11. main_menu test 全过 ===
verify_local_tests "test/features/main_menu/presentation/main_menu_test.dart"

# === 12. commit message ===
verify_commit_message "nightshift T16"

verify_done
