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
  if (qiDelta != null) 'qiDelta': qiDelta,
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

    expect(repo.skillDefs, hasLength(246));
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
}
