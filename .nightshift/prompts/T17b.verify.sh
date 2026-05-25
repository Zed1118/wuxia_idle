#!/bin/bash
# T17b verify · P1.2 B3 UI + B4 R5 + closeout 续作

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T17b"

# === 1. path_guard 白名单 ===
verify_path_guard "lib/features/jianghu/presentation/.+\.dart|lib/features/main_menu/presentation/main_menu\.dart|lib/shared/strings\.dart|lib/core/application/battle_providers\.dart|lib/core/application/battle_providers\.g\.dart|test/features/jianghu/.+\.dart|test/features/main_menu/presentation/main_menu_test\.dart|docs/handoff/p1_2_jianghu_full_closeout_.+\.md|pubspec\.lock"

# === 2. 2 commit B3+B4(本 task 续作 · 不再要求 4 commit) ===
commit_count=$(git log --oneline main..HEAD 2>/dev/null | grep -c "nightshift T17b B[3-4]" || echo 0)
if [ "$commit_count" -lt 2 ]; then
  echo "  本 worktree commit list:"
  git log --oneline main..HEAD | head -10
  verify_fail "P1.2 续作应有 2 batch commit(B3+B4)· 实测 $commit_count"
fi

# === 3. Last commit message 含 nightshift T17b ===
verify_commit_message "nightshift T17b"

# === 4. B3 UI 文件存在 ===
verify_file_exists "lib/features/jianghu/presentation/reputation_panel_screen.dart"
if ! grep -qE "class ReputationPanelScreen" lib/features/jianghu/presentation/reputation_panel_screen.dart; then
  verify_fail "ReputationPanelScreen class 缺"
fi

# === 5. UiStrings 加 12 段(关键 4) ===
for s in "mainMenuJianghu" "reputationPanelTitle" "reputationTierXueTu" "reputationTierWuSheng"; do
  if ! grep -qE "\b$s\s*=" lib/shared/strings.dart; then
    verify_fail "UiStrings 缺 $s"
  fi
done
tier_strs=$(grep -cE "reputationTier(XueTu|SanLiu|ErLiu|YiLiu|JueDing|ZongShi|WuSheng)[[:space:]]*=" lib/shared/strings.dart || echo 0)
if [ "$tier_strs" -lt 7 ]; then
  verify_fail "UiStrings 7 阶 tier 字符串不全 · 实测 $tier_strs"
fi

# === 6. main_menu 江湖 入口 ===
if ! grep -qE "UiStrings\.mainMenuJianghu" lib/features/main_menu/presentation/main_menu.dart; then
  verify_fail "main_menu.dart 缺 UiStrings.mainMenuJianghu 引用"
fi

# === 7. battle_providers 注入 attackPowerMultiplier ===
if ! grep -qE "npcRelationService|attackPowerMultFor" lib/core/application/battle_providers.dart; then
  verify_fail "battle_providers 缺 attackPowerMultiplier 注入(沿 NpcRelationService.attackPowerMultFor)"
fi

# === 8. closeout doc ≤100 行(上限 80 + 容差) ===
closeout_file=$(ls docs/handoff/p1_2_jianghu_full_closeout_*.md 2>/dev/null | head -1)
if [ -z "$closeout_file" ]; then
  verify_fail "closeout doc 缺"
fi
closeout_lines=$(wc -l < "$closeout_file")
if [ "$closeout_lines" -gt 100 ]; then
  verify_fail "closeout doc $closeout_lines 行超 100 上限"
fi

# === 9. flutter build_runner + analyze ===
verify_build_runner_strict
verify_analyze_clean

# === 10. R5 测族全过 ===
if [ -f test/features/jianghu/jianghu_r5_test.dart ]; then
  verify_local_tests "test/features/jianghu/jianghu_r5_test.dart"
fi
verify_local_tests "test/features/main_menu/presentation/main_menu_test.dart"

verify_done
