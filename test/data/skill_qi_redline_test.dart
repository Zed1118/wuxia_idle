import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

Map<String, dynamic> skillYaml({
  SkillType type = SkillType.normalAttack,
  int? qiDelta,
}) => {
  'id': 'skill_qi_fixture',
  'name': '测试招式',
  'description': '测试',
  'type': type.name,
  'powerMultiplier': 500,
  'cooldownTurns': 0,
  'requiresManualTrigger': false,
  'visualEffect': 'none',
  'source': 'technique',
  'qiDelta': ?qiDelta,
};

void main() {
  tearDown(GameRepository.resetForTest);

  test('SkillDef parses explicit positive/zero/negative qi delta', () {
    expect(SkillDef.fromYaml(skillYaml(qiDelta: 20)).qiDelta, 20);
    expect(SkillDef.fromYaml(skillYaml(qiDelta: 0)).qiDelta, 0);
    expect(SkillDef.fromYaml(skillYaml(qiDelta: -60)).qiDelta, -60);
  });

  test('SkillDef rejects a missing qi delta', () {
    expect(() => SkillDef.fromYaml(skillYaml()), throwsA(isA<TypeError>()));
  });

  test('derived qi direction getters are unambiguous', () {
    final gain = SkillDef.fromYaml(skillYaml(qiDelta: 20));
    final neutral = SkillDef.fromYaml(skillYaml(qiDelta: 0));
    final spend = SkillDef.fromYaml(skillYaml(qiDelta: -60));

    expect(gain.generatesQi, isTrue);
    expect(gain.spendsQi, isFalse);
    expect(gain.qiCost, 0);
    expect(neutral.generatesQi, isFalse);
    expect(neutral.spendsQi, isFalse);
    expect(spend.spendsQi, isTrue);
    expect(spend.qiCost, 60);
  });

  test('all production skills declare a bounded qi direction', () async {
    final repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    final cap = repo.numbers.combat.qi.deltaAbsCap;

    expect(repo.skillDefs, hasLength(256));
    for (final skill in repo.skillDefs.values) {
      expect(skill.qiDelta.abs(), lessThanOrEqualTo(cap), reason: skill.id);
      switch (skill.type) {
        case SkillType.normalAttack:
          expect(skill.generatesQi, isTrue, reason: skill.id);
        case SkillType.powerSkill:
        case SkillType.ultimate:
        case SkillType.jointSkill:
          expect(skill.spendsQi, isTrue, reason: skill.id);
      }
    }
  });

  test(
    'loadAllDefs rejects a skill whose qi delta exceeds the configured cap',
    () {
      Future<String> brokenLoader(String path) async {
        final original = await File(path).readAsString();
        if (path != 'data/skills.yaml') return original;
        return original.replaceFirst('qiDelta: 20', 'qiDelta: 101');
      }

      expect(
        GameRepository.loadAllDefs(loader: brokenLoader),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(contains('qiDelta=101'), contains('> 100')),
          ),
        ),
      );
    },
  );

  test(
    'loadAllDefs rejects a skill whose qiDrainPct exceeds the [0, 0.5] bound',
    () {
      Future<String> brokenLoader(String path) async {
        final original = await File(path).readAsString();
        if (path != 'data/skills.yaml') return original;
        // 给首个招式注入越界 qiDrainPct(4 空格缩进对齐字段层)。C1.3.1 断魂庄
        // qi_drain schema 硬界:配置越界应启动 fail-fast,而非战斗中 QiDrainEffect 崩。
        return original.replaceFirst(
          'qiDelta: 20',
          'qiDelta: 20\n    qiDrainPct: 0.6',
        );
      }

      expect(
        GameRepository.loadAllDefs(loader: brokenLoader),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(contains('qiDrainPct'), contains('0.6')),
          ),
        ),
      );
    },
  );
}
