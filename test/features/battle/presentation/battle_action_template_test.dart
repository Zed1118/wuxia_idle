import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_action_template.dart';

SkillDef _skill({
  required String visualEffect,
  SkillType type = SkillType.powerSkill,
  TargetType targetType = TargetType.single,
  bool canInterrupt = false,
}) => SkillDef(
  id: visualEffect,
  name: visualEffect,
  description: '',
  type: type,
  powerMultiplier: 1000,
  qiDelta: -100,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: visualEffect,
  targetType: targetType,
  canInterrupt: canInterrupt,
);

void main() {
  group('battleActionTemplateFor', () {
    test('普攻/拳掌默认近战，近战会移向交锋点且不发远程弹道', () {
      expect(battleActionTemplateFor(null), BattleActionTemplate.melee);
      expect(
        battleActionTemplateFor(_skill(visualEffect: 'heavy_punch')),
        BattleActionTemplate.melee,
      );
      expect(templateMovesToClash(BattleActionTemplate.melee), isTrue);
      expect(templateUsesProjectile(BattleActionTemplate.melee), isFalse);
    });

    test('暗器/飞剑/气劲走远程弹道，人物不移位', () {
      for (final effect in ['hidden_weapon', 'flying_sword_art', 'qi_wave']) {
        final template = battleActionTemplateFor(_skill(visualEffect: effect));
        expect(template, BattleActionTemplate.projectile);
        expect(templateUsesProjectile(template), isTrue);
        expect(templateMovesToClash(template), isFalse);
      }
    });

    test('群体/破招/单体大招分别走 area/control/cinematic', () {
      expect(
        battleActionTemplateFor(
          _skill(visualEffect: 'falling_petals', targetType: TargetType.aoe),
        ),
        BattleActionTemplate.area,
      );
      expect(
        battleActionTemplateFor(
          _skill(visualEffect: 'seal_break', canInterrupt: true),
        ),
        BattleActionTemplate.control,
      );
      expect(
        battleActionTemplateFor(
          _skill(visualEffect: 'dragon_roar', type: SkillType.ultimate),
        ),
        BattleActionTemplate.cinematic,
      );
    });
  });
}
