import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

void main() {
  test('canInterrupt/aiUsePolicy 缺省值', () {
    final y = {
      'id': 's', 'name': 'n', 'description': 'd', 'type': 'powerSkill',
      'powerMultiplier': 1000, 'internalForceCost': 100, 'cooldownTurns': 3,
      'requiresManualTrigger': false, 'visualEffect': 'x',
    };
    final s = SkillDef.fromYaml(y);
    expect(s.canInterrupt, false);
    expect(s.aiUsePolicy, AiUsePolicy.normal);
  });

  test('canInterrupt/aiUsePolicy 显式解析', () {
    final y = {
      'id': 's', 'name': 'n', 'description': 'd', 'type': 'powerSkill',
      'powerMultiplier': 1000, 'internalForceCost': 100, 'cooldownTurns': 3,
      'requiresManualTrigger': false, 'visualEffect': 'x',
      'canInterrupt': true, 'aiUsePolicy': 'saveForInterrupt',
    };
    final s = SkillDef.fromYaml(y);
    expect(s.canInterrupt, true);
    expect(s.aiUsePolicy, AiUsePolicy.saveForInterrupt);
  });
}
