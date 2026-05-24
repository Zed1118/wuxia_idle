#!/bin/bash
# T18 verify · P3.3 PVP + P3.4 sect_event narrative 双合一

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T18"

# === 1. path_guard 白名单 ===
verify_path_guard "data/lore/pvp/.+\.yaml|data/lore/sect_event/.+\.yaml|test/features/pvp/pvp_narrative_loader_test\.dart|test/features/sect/sect_narrative_loader_test\.dart|pubspec\.lock"

# === 2. PVP narrative ≥ 11(基线 1 + delta ≥ 10) ===
pvp_count=$(ls data/lore/pvp/*.yaml 2>/dev/null | wc -l | tr -d ' ')
if [ "$pvp_count" -lt 11 ]; then
  verify_fail "PVP narrative 数 $pvp_count < 11(基线 1 first_blood + delta ≥ 10)"
fi

# === 3. sect_event narrative ≥ 10(基线 2 + delta ≥ 8) ===
sect_count=$(ls data/lore/sect_event/*.yaml 2>/dev/null | wc -l | tr -d ' ')
if [ "$sect_count" -lt 10 ]; then
  verify_fail "sect narrative 数 $sect_count < 10(基线 2 tournament + delta ≥ 8)"
fi

# === 4. PVP narrative 关键 trigger 覆盖 ===
for kind in "rank_up_sanLiu" "rank_up_erLiu" "rank_up_yiLiu" "rank_up_jueDing" "rank_up_zongShi" "rank_up_wuSheng" "rank_down" "monthly_reset"; do
  if ! grep -rqE "kind:\s*$kind\b" data/lore/pvp/ 2>/dev/null; then
    verify_fail "PVP narrative 缺 trigger.kind=$kind"
  fi
done

# === 5. sect_event narrative 三 type 覆盖 ===
for t in "mission" "crisis"; do
  if ! grep -rqE "^type:\s*$t\b" data/lore/sect_event/ 2>/dev/null; then
    verify_fail "sect_event narrative 缺 type=$t"
  fi
done
# tournament 至少 3 个(基线 2 + 新 ≥ 1)
tournament_count=$(grep -lE "^type:\s*tournament\b" data/lore/sect_event/*.yaml 2>/dev/null | wc -l | tr -d ' ')
if [ "$tournament_count" -lt 3 ]; then
  verify_fail "sect_event tournament narrative $tournament_count < 3(基线 2 + delta ≥ 1)"
fi

# === 6. R4 loader 测文件存在 ===
verify_file_exists "test/features/pvp/pvp_narrative_loader_test.dart"
verify_file_exists "test/features/sect/sect_narrative_loader_test.dart"

# === 7. 黑名单词扫描(全 PVP + sect narrative)===
for f in data/lore/pvp/*.yaml data/lore/sect_event/*.yaml; do
  if [ -f "$f" ]; then
    verify_blacklist_words "$f"
  fi
done

# === 8. id 与 文件名一致(每个 yaml 的 id 字段等文件名 stem) ===
for f in data/lore/pvp/*.yaml data/lore/sect_event/*.yaml; do
  if [ -f "$f" ]; then
    stem=$(basename "$f" .yaml)
    actual_id=$(grep -E "^id:\s*" "$f" | head -1 | sed -E 's/^id:\s*//; s/\s*$//')
    if [ "$actual_id" != "$stem" ]; then
      verify_fail "$f id='$actual_id' != 文件名 stem='$stem'"
    fi
  fi
done

# === 9. flutter analyze + 测全过 ===
verify_analyze_clean
verify_local_tests "test/features/pvp/pvp_narrative_loader_test.dart"
verify_local_tests "test/features/sect/sect_narrative_loader_test.dart"

# === 10. commit message ===
verify_commit_message "nightshift T18"

verify_done
