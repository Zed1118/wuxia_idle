import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

/// Phase 4 W14-1 · encounters.yaml parse + GameRepository 红线测试。
///
/// 不依赖 Isar(纯 GameRepository.loadAllDefs 路径)。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  group('encounters.yaml 加载', () {
    test(
        '45 条 encounter 全部解析成功 '
        '(W14-1 3 + W14-2 12 + W15 6 + W15-r2 7 + W15 C-1 2 + W16 节日 6 + W17 节日 2 + W17 polish-C 2 + W18-A2 4 + P1 #37 yu_zhong_qiao_men 挂回 1)',
        () {
      final repo = GameRepository.instance;
      expect(repo.encounterDefs.length, 45,
          reason:
              'W14-1 3 + W14-2 12 + W15 #37 第 1 批 6 + 第 2 批 7 + C-1 收尾 2 + W16 节日 6 + W17 节日 2 + W17 polish-C 2 + W18-A2 触发条件 4 + P1 #37 yu_zhong_qiao_men 挂回 1');
      // W14-1 3 条必须仍在
      expect(
        repo.encounterDefs.keys,
        containsAll(
            {'bamboo_listen_rain', 'cha_ting_dui_ju', 'du_ke_wen_dao'}),
      );
      // W14-2 抽样核对若干新 id
      expect(
        repo.encounterDefs.keys,
        containsAll({
          'gu_jian_zhong_yin',
          'cang_jing_ge_wu',
          'shan_lin_qi_yu',
          'xuan_ya_pu_bu_li_lian',
          'duan_ya_chui_lian',
          'ye_xing_xun_dao',
        }),
      );
      // W15 #37 第 1 批 6 条挂回核对
      expect(
        repo.encounterDefs.keys,
        containsAll({
          'xue_ye_gu_qin',
          'feng_xue_gu_dian',
          'ye_du_gu_chuan',
          'han_mei_ying_xue',
          'xing_chen_wu_dao',
          'qiu_ye_wei_qi',
        }),
        reason: 'W15 #37 第 1 批 6 条挂回:雨雪夜主题为主',
      );
      // W15 #37 第 2 批 7 条挂回核对(tier 1-2/6/7 池补)
      expect(
        repo.encounterDefs.keys,
        containsAll({
          'shi_dao_shou_hu',
          'mu_chan_dui_yin',
          'huang_sha_ke_zhan',
          'xiang_ye_shen_ji',
          'luo_hua_jian_yuan',
          'shan_ya_can_bei',
          'jue_ding_feng_qi',
        }),
        reason: 'W15 #37 第 2 批 7 条:tier 1-2/6/7 池 unlockSkill 补',
      );
      // W15 C-1 收尾 2 条挂回核对(tier 7 long_yin / wu_ming 引用补)
      expect(
        repo.encounterDefs.keys,
        containsAll({'huang_miao_jiu_seng', 'jiu_lou_jue_yin'}),
        reason: 'W15 C-1 收尾 2 条:tier 7 long_yin / wu_ming 池 unlockSkill 补',
      );
      // W16 节日 encounter 6 条核对(GDD §12.4 接口预留首批落)
      expect(
        repo.encounterDefs.keys,
        containsAll({
          'chun_jie_shou_sui',
          'yuan_xiao_guan_deng',
          'duan_wu_du_long_zhou',
          'qi_xi_xi_qiao',
          'zhong_qiu_yue_xia_du',
          'chong_yang_deng_gao',
        }),
        reason: 'W16 节日 encounter 6 条:春节/元宵/端午/七夕/中秋/重阳 各 1 条',
      );
      // W17 节日 encounter 2 条核对(framework 扩 chuXi/qingMingJie)
      expect(
        repo.encounterDefs.keys,
        containsAll({
          'chu_xi_ci_sui',
          'qing_ming_yu_si',
        }),
        reason: 'W17 节日 encounter 2 条:除夕/清明 各 1 条',
      );
      // W17 polish-C 2 条挂回核对(#37 余 8 → 余 6;qiu_quan / wu_xia_yi 池补)
      expect(
        repo.encounterDefs.keys,
        containsAll({
          'huang_yuan_yi_zhong',
          'jiang_xin_ye_hua',
        }),
        reason: 'W17 polish-C 2 条:荒原遗冢→求拳 / 江心夜话→武侠意',
      );
      // W17 polish-C 挂回后 qiu_quan / wu_xia_yi 必须被 encounter outcome 引用
      final allUnlockSkillIds = <String>{
        for (final enc in repo.allEncounters)
          for (final outcome in enc.outcomeMapping.values)
            if (outcome.type == OutcomeType.unlockSkill &&
                outcome.skillId != null)
              outcome.skillId!,
      };
      expect(allUnlockSkillIds, contains('skill_encounter_qiu_quan'),
          reason: 'W17 polish-C 挂回后 qiu_quan 必须被 encounter outcome 引用');
      expect(allUnlockSkillIds, contains('skill_encounter_wu_xia_yi'),
          reason: 'W17 polish-C 挂回后 wu_xia_yi 必须被 encounter outcome 引用');
    });

    test('bamboo_listen_rain · techniqueInsight + lingQiao 100 + 解锁招式',
        () {
      final def = GameRepository.instance.findEncounter('bamboo_listen_rain')!;
      expect(def.type, EncounterType.techniqueInsight);
      expect(def.trigger.schoolKillThreshold[TechniqueSchool.lingQiao], 100);
      expect(def.trigger.fortuneRequired, 3);
      expect(def.baseProbability, closeTo(0.4, 1e-9));

      final insight = def.outcomeMapping['insight_success']!;
      expect(insight.type, OutcomeType.unlockSkill);
      expect(insight.skillId, 'skill_encounter_ting_yu_jian');

      final partial = def.outcomeMapping['practice_partial']!;
      expect(partial.type, OutcomeType.attributeBonus);
      expect(partial.attributeKey, AttributeKey.agility);
      expect(partial.attributeDelta, 1);
    });

    test('cha_ting_dui_ju · fortuneEvent + 3 流派 10 杀 + fortune 5', () {
      final def = GameRepository.instance.findEncounter('cha_ting_dui_ju')!;
      expect(def.type, EncounterType.fortuneEvent);
      expect(def.trigger.schoolKillThreshold[TechniqueSchool.gangMeng], 10);
      expect(def.trigger.schoolKillThreshold[TechniqueSchool.lingQiao], 10);
      expect(def.trigger.schoolKillThreshold[TechniqueSchool.yinRou], 10);
      expect(def.trigger.fortuneRequired, 5);
    });

    test('du_ke_wen_dao · 仅 fortune 软概率,无 school 门槛', () {
      final def = GameRepository.instance.findEncounter('du_ke_wen_dao')!;
      expect(def.type, EncounterType.fortuneEvent);
      expect(def.trigger.schoolKillThreshold, isEmpty);
      expect(def.trigger.fortuneRequired, 4);
      expect(def.baseProbability, closeTo(0.5, 1e-9));
    });

    test('allEncounters 返回按 id 字典序', () {
      final ids =
          GameRepository.instance.allEncounters.map((e) => e.id).toList();
      final sorted = [...ids]..sort();
      expect(ids, sorted, reason: 'allEncounters 必须字典序');
      // 包含校验(约束语义,不锚瞬时 first 位次,memory
      // feedback_red_line_test_semantics:后续加 encounter id 字典序在前)
      expect(ids, contains('bamboo_listen_rain'));
    });

    test('findEncounter 未配返回 null(避免 caller try/catch)', () {
      expect(GameRepository.instance.findEncounter('nope_not_exist'), isNull);
    });

    test('resolveOutcome 未配的 outcomeId fallback 到 OutcomeType.none', () {
      final def = GameRepository.instance.findEncounter('du_ke_wen_dao')!;
      final outcome = def.resolveOutcome('skip');
      expect(outcome.type, OutcomeType.none);
    });
  });

  group('EncounterDef.fromYaml 边界', () {
    test('baseProbability 越界 → 抛 StateError', () {
      expect(
        () => EncounterDef.fromYaml({
          'id': 'enc_bad',
          'type': 'fortuneEvent',
          'trigger': {},
          'baseProbability': 1.5,
          'outcomeMapping': {},
        }),
        throwsA(isA<StateError>()),
      );
    });

    test('unlockSkill 缺 skillId → 抛 StateError', () {
      expect(
        () => OutcomeDef.fromYaml({'type': 'unlockSkill'}),
        throwsA(isA<StateError>()),
      );
    });

    test('attributeBonus 缺 attributeKey → 抛 StateError', () {
      expect(
        () => OutcomeDef.fromYaml({'type': 'attributeBonus'}),
        throwsA(isA<StateError>()),
      );
    });
  });

  // C-W14-2:biome/weather trigger 维度解析
  group('encounters.yaml W14-2 biome/weather 维度解析', () {
    test('gu_jian_zhong_yin 解 swordTomb 60 + mist 30', () {
      final def = GameRepository.instance.findEncounter('gu_jian_zhong_yin')!;
      expect(def.trigger.biomeMinutes[EncounterBiome.swordTomb], 60);
      expect(def.trigger.weatherMinutes[EncounterWeather.mist], 30);
      expect(def.trigger.fortuneRequired, 4);
      expect(def.outcomeMapping['find_relic_sword']!.type,
          OutcomeType.unlockSkill);
    });

    test('cang_jing_ge_wu 解 temple 120 + 无 weather', () {
      final def = GameRepository.instance.findEncounter('cang_jing_ge_wu')!;
      expect(def.trigger.biomeMinutes[EncounterBiome.temple], 120);
      expect(def.trigger.weatherMinutes, isEmpty);
    });

    test('ye_xing_xun_dao 仅 weather (night 60) 无 biome', () {
      final def = GameRepository.instance.findEncounter('ye_xing_xun_dao')!;
      expect(def.trigger.weatherMinutes[EncounterWeather.night], 60);
      expect(def.trigger.biomeMinutes, isEmpty);
    });

    test('qun_xia_tu 三维度同时(school + biome + fortune)', () {
      final def = GameRepository.instance.findEncounter('qun_xia_tu')!;
      expect(def.trigger.schoolKillThreshold[TechniqueSchool.gangMeng], 5);
      expect(def.trigger.biomeMinutes[EncounterBiome.drillGround], 30);
      expect(def.trigger.fortuneRequired, 3);
    });
  });

  // C-W15 收尾:tier 7 long_yin / wu_ming 引用补
  group('encounters.yaml W15 C-1 收尾 2 条', () {
    test('huang_miao_jiu_seng · temple 90 + fortune 7 + unlock long_yin', () {
      final def =
          GameRepository.instance.findEncounter('huang_miao_jiu_seng')!;
      expect(def.type, EncounterType.techniqueInsight);
      expect(def.trigger.biomeMinutes[EncounterBiome.temple], 90);
      expect(def.trigger.fortuneRequired, 7);
      expect(def.baseProbability, closeTo(0.2, 1e-9));

      final healing = def.outcomeMapping['learn_healing']!;
      expect(healing.type, OutcomeType.attributeBonus);
      expect(healing.attributeKey, AttributeKey.constitution);
      expect(healing.attributeDelta, 1);

      final lore = def.outcomeMapping['learn_lore']!;
      expect(lore.type, OutcomeType.unlockSkill);
      expect(lore.skillId, 'skill_encounter_long_yin');
    });

    test('jiu_lou_jue_yin · inn 90 + fortune 7 + unlock wu_ming', () {
      final def = GameRepository.instance.findEncounter('jiu_lou_jue_yin')!;
      expect(def.type, EncounterType.techniqueInsight);
      expect(def.trigger.biomeMinutes[EncounterBiome.inn], 90);
      expect(def.trigger.fortuneRequired, 7);
      expect(def.baseProbability, closeTo(0.2, 1e-9));

      final respect = def.outcomeMapping['earn_respect']!;
      expect(respect.type, OutcomeType.attributeBonus);
      expect(respect.attributeKey, AttributeKey.constitution);
      expect(respect.attributeDelta, 1);

      final avoid = def.outcomeMapping['clever_avoid']!;
      expect(avoid.type, OutcomeType.unlockSkill);
      expect(avoid.skillId, 'skill_encounter_wu_ming');
    });

    test('C-1 收尾后 tier 7 long_yin / wu_ming 被 encounter 引用', () {
      final repo = GameRepository.instance;
      final allUnlockSkillIds = <String>{
        for (final enc in repo.allEncounters)
          for (final outcome in enc.outcomeMapping.values)
            if (outcome.type == OutcomeType.unlockSkill && outcome.skillId != null)
              outcome.skillId!,
      };
      expect(allUnlockSkillIds, contains('skill_encounter_long_yin'),
          reason: 'C-1 收尾后 long_yin 必须被 encounter outcome 引用');
      expect(allUnlockSkillIds, contains('skill_encounter_wu_ming'),
          reason: 'C-1 收尾后 wu_ming 必须被 encounter outcome 引用');
    });
  });

  // C-W14-2:EncounterTrigger.fromYaml 边界 — 错误枚举值 → 抛 ArgumentError
  group('EncounterTrigger.fromYaml 边界', () {
    test('未知 biome 枚举值 → 抛错', () {
      expect(
        () => EncounterTrigger.fromYaml({
          'biomeMinutes': {'wuhuhu_unknown': 30},
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('未知 weather 枚举值 → 抛错', () {
      expect(
        () => EncounterTrigger.fromYaml({
          'weatherMinutes': {'tornado_unknown': 30},
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    // W16 GDD §12.4 festivalRequired 解析
    test('festivalRequired=null（缺字段）→ trigger.festivalRequired=null', () {
      final t = EncounterTrigger.fromYaml({});
      expect(t.festivalRequired, isNull);
    });

    test('festivalRequired=chunJie → 正确解析为 Festival.chunJie', () {
      final t = EncounterTrigger.fromYaml({'festivalRequired': 'chunJie'});
      expect(t.festivalRequired, Festival.chunJie);
    });

    test('festivalRequired=zhongQiu → 正确解析为 Festival.zhongQiu', () {
      final t = EncounterTrigger.fromYaml({'festivalRequired': 'zhongQiu'});
      expect(t.festivalRequired, Festival.zhongQiu);
    });

    test('未知 festival 枚举值 → 抛错', () {
      expect(
        () => EncounterTrigger.fromYaml({
          'festivalRequired': 'unknownFestival_oops',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
