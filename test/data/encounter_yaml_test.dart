import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/enums.dart';

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
    test('3 条 vertical slice encounter 全部解析成功', () {
      final repo = GameRepository.instance;
      expect(repo.encounterDefs.length, 3,
          reason: 'C-W14-1 vertical slice 3 条');
      expect(
        repo.encounterDefs.keys.toSet(),
        {'bamboo_listen_rain', 'cha_ting_dui_ju', 'du_ke_wen_dao'},
      );
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
      expect(ids, ['bamboo_listen_rain', 'cha_ting_dui_ju', 'du_ke_wen_dao']);
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
}
