import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

void main() {
  test('canInterrupt/aiUsePolicy 缺省值', () {
    final y = {
      'id': 's',
      'name': 'n',
      'description': 'd',
      'type': 'powerSkill',
      'powerMultiplier': 1000,
      'internalForceCost': 100,
      'cooldownTurns': 3,
      'requiresManualTrigger': false,
      'visualEffect': 'x',
    };
    final s = SkillDef.fromYaml(y);
    expect(s.canInterrupt, false);
    expect(s.aiUsePolicy, AiUsePolicy.normal);
  });

  test('canInterrupt/aiUsePolicy 显式解析', () {
    final y = {
      'id': 's',
      'name': 'n',
      'description': 'd',
      'type': 'powerSkill',
      'powerMultiplier': 1000,
      'internalForceCost': 100,
      'cooldownTurns': 3,
      'requiresManualTrigger': false,
      'visualEffect': 'x',
      'canInterrupt': true,
      'aiUsePolicy': 'saveForInterrupt',
    };
    final s = SkillDef.fromYaml(y);
    expect(s.canInterrupt, true);
    expect(s.aiUsePolicy, AiUsePolicy.saveForInterrupt);
  });

  test('style 缺省 null / 显式解析为 TechniqueSchool(波A build gate)', () {
    final base = {
      'id': 's',
      'name': 'n',
      'description': 'd',
      'type': 'powerSkill',
      'powerMultiplier': 1000,
      'internalForceCost': 100,
      'cooldownTurns': 3,
      'requiresManualTrigger': false,
      'visualEffect': 'x',
    };
    expect(SkillDef.fromYaml(base).style, isNull);
    expect(
      SkillDef.fromYaml({...base, 'style': 'lingQiao'}).style,
      TechniqueSchool.lingQiao,
    );
  });

  test('Phase0A behavior requires a finite nonnegative cooldownSeconds', () {
    final base = <String, dynamic>{
      'id': 'phase0a',
      'name': 'n',
      'description': 'd',
      'type': 'powerSkill',
      'powerMultiplier': 1000,
      'qiDelta': -10,
      'cooldownTurns': 3,
      'requiresManualTrigger': true,
      'visualEffect': 'x',
      'source': 'special',
      'targetType': 'aoe',
      'phase0aBehavior': {
        'geometry': {'shape': 'radial', 'anchor': 'caster', 'radius': 10},
        'effects': [
          {'type': 'pull', 'destinationRadius': 1},
        ],
      },
    };

    expect(() => SkillDef.fromYaml(base), throwsA(isA<StateError>()));
    expect(
      () => SkillDef.fromYaml({...base, 'cooldownSeconds': -1}),
      throwsA(isA<StateError>()),
    );
    final skill = SkillDef.fromYaml({...base, 'cooldownSeconds': 2.5});
    expect(skill.cooldownSeconds, 2.5);
  });

  test('phase0aEnemyCooldownSeconds 只接受有限非负数', () {
    final base = <String, dynamic>{
      'id': 'enemy_skill',
      'name': 'n',
      'description': 'd',
      'type': 'powerSkill',
      'powerMultiplier': 1000,
      'qiDelta': -10,
      'cooldownTurns': 3,
      'requiresManualTrigger': false,
      'visualEffect': 'x',
    };

    expect(
      () => SkillDef.fromYaml({...base, 'phase0aEnemyCooldownSeconds': -1}),
      throwsA(isA<StateError>()),
    );
    final skill = SkillDef.fromYaml({
      ...base,
      'phase0aEnemyCooldownSeconds': 3.0,
    });
    expect(skill.phase0aEnemyCooldownSeconds, 3);
  });
}
