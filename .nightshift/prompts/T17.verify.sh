#!/bin/bash
# T17 verify · P1.2 §12.1 江湖恩怨 + §12.2 声望 全 4 batch

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T17"

# === 1. path_guard 白名单 ===
verify_path_guard "lib/features/jianghu/.+\.dart|lib/features/main_menu/presentation/main_menu\.dart|lib/features/encounter/application/encounter_service\.dart|lib/features/encounter/application/encounter_service_providers\.dart|lib/features/encounter/application/encounter_service_providers\.g\.dart|lib/features/encounter/domain/encounter_def\.dart|lib/shared/strings\.dart|lib/data/numbers_config\.dart|lib/data/stage_def\.dart|lib/data/isar_setup\.dart|lib/core/application/battle_providers\.dart|lib/core/application/battle_providers\.g\.dart|data/numbers\.yaml|data/factions\.yaml|data/stages\.yaml|data/encounters\.yaml|test/features/jianghu/.+\.dart|test/features/main_menu/presentation/main_menu_test\.dart|docs/handoff/p1_2_jianghu_full_closeout_.+\.md|pubspec\.lock"

# === 2. 4 commit 都在 ===
commit_count=$(git log --oneline main..HEAD 2>/dev/null | grep -c "nightshift T17 B[1-4]" || echo 0)
if [ "$commit_count" -lt 4 ]; then
  echo "  本 worktree commit list:"
  git log --oneline main..HEAD | head -10
  verify_fail "P1.2 应有 4 batch commit(B1+B2+B3+B4)· 实测 $commit_count"
fi

# === 3. Last commit message 含 nightshift T17 ===
verify_commit_message "nightshift T17"

# === 4. B1 schema 文件存在 ===
verify_file_exists "lib/features/jianghu/domain/reputation.dart"
verify_file_exists "lib/features/jianghu/domain/npc_relation.dart"
verify_file_exists "data/factions.yaml"
if ! grep -qE "^jianghu:" data/numbers.yaml; then
  verify_fail "numbers.yaml 缺 jianghu: 段"
fi
if ! grep -qE "reputation_tiers:" data/numbers.yaml; then
  verify_fail "numbers.yaml.jianghu 缺 reputation_tiers"
fi
if ! grep -qE "enmity_combat_modifier:" data/numbers.yaml; then
  verify_fail "numbers.yaml.jianghu 缺 enmity_combat_modifier"
fi

# === 5. B1 schema NumbersConfig 解析扩展 ===
if ! grep -qE "class JianghuConfig" lib/data/numbers_config.dart; then
  verify_fail "numbers_config.dart 缺 JianghuConfig class"
fi
if ! grep -qE "jianghu" lib/data/numbers_config.dart; then
  verify_fail "numbers_config.dart NumbersConfig 缺 jianghu 字段"
fi

# === 6. B1 IsarSetup schema 注册 ===
if ! grep -qE "ReputationSchema" lib/data/isar_setup.dart; then
  verify_fail "isar_setup.dart 缺 ReputationSchema 注册"
fi
if ! grep -qE "NpcRelationSchema" lib/data/isar_setup.dart; then
  verify_fail "isar_setup.dart 缺 NpcRelationSchema 注册"
fi

# === 7. B2 service 文件存在 ===
verify_file_exists "lib/features/jianghu/application/reputation_service.dart"
verify_file_exists "lib/features/jianghu/application/npc_relation_service.dart"
verify_file_exists "lib/features/jianghu/application/jianghu_providers.dart"
if ! grep -qE "class ReputationService" lib/features/jianghu/application/reputation_service.dart; then
  verify_fail "ReputationService class 缺"
fi
if ! grep -qE "applyDelta" lib/features/jianghu/application/reputation_service.dart; then
  verify_fail "ReputationService 缺 applyDelta"
fi
if ! grep -qE "tierOf" lib/features/jianghu/application/reputation_service.dart; then
  verify_fail "ReputationService 缺 tierOf"
fi
if ! grep -qE "attackPowerMultFor" lib/features/jianghu/application/npc_relation_service.dart; then
  verify_fail "NpcRelationService 缺 attackPowerMultFor"
fi

# === 8. B2 encounter 集成 ===
if ! grep -qE "affectsReputation|affects_reputation" lib/features/encounter/application/encounter_service.dart; then
  verify_fail "encounter_service 缺 affectsReputation 消费 hook"
fi

# === 9. B3 UI 文件存在 ===
verify_file_exists "lib/features/jianghu/presentation/reputation_panel_screen.dart"
if ! grep -qE "class ReputationPanelScreen" lib/features/jianghu/presentation/reputation_panel_screen.dart; then
  verify_fail "ReputationPanelScreen class 缺"
fi

# === 10. B3 UiStrings 加 12 段 ===
if ! grep -qE "mainMenuJianghu\s*=" lib/shared/strings.dart; then
  verify_fail "UiStrings 缺 mainMenuJianghu"
fi
if ! grep -qE "reputationPanelTitle\s*=" lib/shared/strings.dart; then
  verify_fail "UiStrings 缺 reputationPanelTitle"
fi
if ! grep -qE "reputationTierXueTu\s*=" lib/shared/strings.dart; then
  verify_fail "UiStrings 缺 reputationTierXueTu"
fi
if ! grep -qE "reputationTierWuSheng\s*=" lib/shared/strings.dart; then
  verify_fail "UiStrings 缺 reputationTierWuSheng"
fi
tier_strs=$(grep -cE "reputationTier(XueTu|SanLiu|ErLiu|YiLiu|JueDing|ZongShi|WuSheng)\s*=" lib/shared/strings.dart || echo 0)
if [ "$tier_strs" -lt 7 ]; then
  verify_fail "UiStrings 7 阶 tier 字符串不全 · 实测 $tier_strs"
fi

# === 11. B3 main_menu 江湖 入口 ===
if ! grep -qE "UiStrings\.mainMenuJianghu" lib/features/main_menu/presentation/main_menu.dart; then
  verify_fail "main_menu.dart 缺 UiStrings.mainMenuJianghu 引用"
fi

# === 12. B3 battle_providers 注入 attackPowerMultiplier ===
if ! grep -qE "npcRelationService|attackPowerMultFor" lib/core/application/battle_providers.dart; then
  verify_fail "battle_providers 缺 attackPowerMultiplier 注入(沿 NpcRelationService.attackPowerMultFor)"
fi

# === 13. B4 closeout doc ≤100 行(上限 80 + 容差) ===
closeout_file=$(ls docs/handoff/p1_2_jianghu_full_closeout_*.md 2>/dev/null | head -1)
if [ -z "$closeout_file" ]; then
  verify_fail "closeout doc 缺"
fi
closeout_lines=$(wc -l < "$closeout_file")
if [ "$closeout_lines" -gt 100 ]; then
  verify_fail "closeout doc $closeout_lines 行超 100 上限"
fi

# === 14. flutter build_runner + analyze ===
verify_build_runner_strict
verify_analyze_clean

# === 15. R5 测族 + service 测全过 ===
if [ -f test/features/jianghu/jianghu_r5_test.dart ]; then
  verify_local_tests "test/features/jianghu/jianghu_r5_test.dart"
fi
if [ -f test/features/jianghu/reputation_service_test.dart ]; then
  verify_local_tests "test/features/jianghu/reputation_service_test.dart"
fi
if [ -f test/features/jianghu/npc_relation_service_test.dart ]; then
  verify_local_tests "test/features/jianghu/npc_relation_service_test.dart"
fi
verify_local_tests "test/features/main_menu/presentation/main_menu_test.dart"

verify_done
