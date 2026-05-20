#!/bin/bash
# T02 verify · encounters.yaml +9 + encounter_skills.yaml +5
set -uo pipefail

ENC="data/encounters.yaml"
SKILL="data/encounter_skills.yaml"
TEST="test/data/encounters_loader_test.dart"

for f in "$ENC" "$SKILL" "$TEST"; do
  test -f "$f" || { echo "VERIFY FAIL: $f missing"; exit 1; }
done

# 1. 5 新 techniqueInsight id 都在
for id in qing_lin_si_yu gu_dao_chi_jian mo_jian_ru_yu xue_ye_xing_kong chuan_long_dan_xin; do
  grep -q "id: $id$" "$ENC" || { echo "VERIFY FAIL: insight $id missing"; exit 1; }
done

# 2. 4 新 fortuneEvent id 都在
for id in qin_lou_fang_you gu_si_qiu_shu ma_kuai_song_hua xian_zhou_yi_lu; do
  grep -q "id: $id$" "$ENC" || { echo "VERIFY FAIL: fortune $id missing"; exit 1; }
done

# 3. 5 新 skill id 都在
for id in skill_encounter_tian_xin_ting_yu skill_encounter_gu_dao_jian_yi skill_encounter_mo_jian_xiang_xin skill_encounter_xue_ye_xing_yi skill_encounter_chuan_long_xiao_ge; do
  grep -q "id: $id$" "$SKILL" || { echo "VERIFY FAIL: skill $id missing"; exit 1; }
done

# 4. techniqueInsight 总数 = 25
INSIGHT_COUNT=$(grep -c "type: techniqueInsight$" "$ENC")
if [ "$INSIGHT_COUNT" -ne 25 ]; then
  echo "VERIFY FAIL: techniqueInsight count $INSIGHT_COUNT != 25"
  exit 1
fi

# 5. fortuneEvent 总数 = 28
FORTUNE_COUNT=$(grep -c "type: fortuneEvent$" "$ENC")
if [ "$FORTUNE_COUNT" -ne 28 ]; then
  echo "VERIFY FAIL: fortuneEvent count $FORTUNE_COUNT != 28"
  exit 1
fi

# 6. skill 总数 ≥ 40(原 35-36 + 5)
SKILL_COUNT=$(grep -c "^  - id: skill_encounter_" "$SKILL")
if [ "$SKILL_COUNT" -lt 40 ]; then
  echo "VERIFY FAIL: encounter_skills count $SKILL_COUNT < 40"
  exit 1
fi

# 7. flutter 工具链 + analyze
flutter pub get >/dev/null 2>&1 || { echo "VERIFY FAIL: pub get"; exit 1; }
dart run build_runner build --delete-conflicting-outputs >/dev/null 2>&1 || echo "VERIFY WARN: build_runner non-zero"
flutter analyze --fatal-warnings >/dev/null 2>&1 || { echo "VERIFY FAIL: analyze"; exit 1; }

# 8. 局部 loader test pass
flutter test "$TEST" >/dev/null 2>&1 || { echo "VERIFY FAIL: encounters_loader_test 不通过"; exit 1; }

# 9. commit message
git log -1 --pretty=%s | grep -q "nightshift T02" || { echo "VERIFY FAIL: no nightshift T02 commit"; exit 1; }

# 10. 改动越界(git diff-tree 不 git show --name-only)
CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD)
CHANGED_OUTSIDE=$(echo "$CHANGED" | grep -vE "^data/encounters\.yaml$|^data/encounter_skills\.yaml$|^test/data/encounters_loader_test\.dart$|^$" || true)
if [ -n "$CHANGED_OUTSIDE" ]; then
  echo "VERIFY FAIL: T02 改动越界:"
  echo "$CHANGED_OUTSIDE"
  exit 1
fi

echo "VERIFY PASS: T02 (insight=$INSIGHT_COUNT, fortune=$FORTUNE_COUNT, skill=$SKILL_COUNT)"
