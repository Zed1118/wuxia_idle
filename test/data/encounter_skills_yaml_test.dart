import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/enums.dart';

/// Phase 4 W14-3-A · encounter_skills.yaml parse + 红线测试。
///
/// 验证:
///   - 35 招全部加载到 skillDefs(与 skills.yaml 同 Map)+ encounterSkillIds 集合
///   - 6 个 W14-1/W14-2 已引用的 unlock id(★)全部存在
///   - 7 阶覆盖度(每阶 ≥ 1)
///   - 每招红线:tier ∈ [1,7] / parentTechniqueDefId == null /
///     powerMultiplier ≤ tier cap / ≤ 8000 全局红线
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  group('encounter_skills.yaml 加载', () {
    test('35 招全部解析(7 阶 × 5)', () {
      final ids = GameRepository.instance.encounterSkillIds;
      expect(ids.length, 35);
    });

    test('6 个 W14-1/W14-2 引用的 unlock id 全部存在', () {
      final ids = GameRepository.instance.encounterSkillIds;
      expect(
        ids,
        containsAll([
          'skill_encounter_ting_yu_jian',   // W14-1 bamboo_listen_rain
          'skill_encounter_relic_blade',    // W14-2 gu_jian_zhong_yin
          'skill_encounter_water_qi',       // W14-2 xuan_ya_pu_bu_li_lian
          'skill_encounter_ice_break',      // W14-2 duan_ya_chui_lian
          'skill_encounter_night_strike',   // W14-2 ye_xing_xun_dao
          'skill_encounter_drill_strike',   // W14-2 qun_xia_tu
        ]),
      );
    });

    test('每招 isEncounterSkill=true(parent 为空 + tier 非空)', () {
      final ids = GameRepository.instance.encounterSkillIds;
      for (final id in ids) {
        final s = GameRepository.instance.skillDefs[id]!;
        expect(s.isEncounterSkill, isTrue, reason: '$id 应为奇遇招式');
        expect(s.parentTechniqueDefId, isNull, reason: '$id parent 应为空');
        expect(s.tier, isNotNull, reason: '$id tier 必填');
      }
    });

    test('7 阶全覆盖(每阶 ≥ 1)', () {
      final tiers = GameRepository.instance.encounterSkillIds
          .map((id) => GameRepository.instance.skillDefs[id]!.tier!)
          .toSet();
      expect(tiers, {1, 2, 3, 4, 5, 6, 7});
    });

    test('tier 倍率 cap 红线(1500/2000/2500/3000/4000/5500/8000)', () {
      const caps = [1500, 2000, 2500, 3000, 4000, 5500, 8000];
      for (final id in GameRepository.instance.encounterSkillIds) {
        final s = GameRepository.instance.skillDefs[id]!;
        final cap = caps[s.tier! - 1];
        expect(s.powerMultiplier, lessThanOrEqualTo(cap),
            reason: '$id tier=${s.tier} 越 cap $cap');
        expect(s.powerMultiplier, lessThanOrEqualTo(8000),
            reason: 'GDD §5.4 全局招式倍率红线 8000');
      }
    });

    test('id 全部以 skill_encounter_ 开头(命名约定)', () {
      for (final id in GameRepository.instance.encounterSkillIds) {
        expect(id, startsWith('skill_encounter_'),
            reason: 'encounter skill id 必须 skill_encounter_ 前缀');
      }
    });

    test('ting_yu_jian tier=3 / type=powerSkill / cap=2500 内', () {
      final s = GameRepository.instance.skillDefs[
          'skill_encounter_ting_yu_jian']!;
      expect(s.tier, 3);
      expect(s.type, SkillType.powerSkill);
      expect(s.powerMultiplier, lessThanOrEqualTo(2500));
      expect(s.isEncounterSkill, isTrue);
    });

    test('ice_break tier=6 / cap=5500 内(后期奇遇)', () {
      final s = GameRepository.instance.skillDefs[
          'skill_encounter_ice_break']!;
      expect(s.tier, 6);
      expect(s.powerMultiplier, lessThanOrEqualTo(5500));
    });

    test('encounters.yaml unlock outcome 引用全部命中 encounter skill 池',
        () {
      final encounterRefs = <String>{};
      for (final def in GameRepository.instance.encounterDefs.values) {
        for (final outcome in def.outcomeMapping.values) {
          if (outcome.skillId != null) encounterRefs.add(outcome.skillId!);
        }
      }
      expect(encounterRefs, isNotEmpty,
          reason: '至少 6 条 W14-1/W14-2 encounter 有 unlock outcome');
      final pool = GameRepository.instance.encounterSkillIds;
      for (final ref in encounterRefs) {
        expect(pool, contains(ref),
            reason: 'encounter outcome 引用 $ref 必须在 encounter skill 池');
      }
    });
  });
}
