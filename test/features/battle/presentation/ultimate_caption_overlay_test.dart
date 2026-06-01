import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/presentation/ultimate_caption_overlay.dart';

SkillDef _skill(SkillType type) => SkillDef(
      id: 't',
      name: '测试招',
      description: '',
      type: type,
      powerMultiplier: 100,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      parentTechniqueDefId: null,
      visualEffect: '',
    );

void main() {
  test('ultimate / jointSkill → true', () {
    expect(isUltimateCaptionSkill(_skill(SkillType.ultimate)), true);
    expect(isUltimateCaptionSkill(_skill(SkillType.jointSkill)), true);
  });

  test('normalAttack / powerSkill / null → false', () {
    expect(isUltimateCaptionSkill(_skill(SkillType.normalAttack)), false);
    expect(isUltimateCaptionSkill(_skill(SkillType.powerSkill)), false);
    expect(isUltimateCaptionSkill(null), false);
  });
}
