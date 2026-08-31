import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/phase0a_skill_behavior.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_tactical_skill_binding.dart';

SkillDef tacticalSkill(double cooldownSeconds) => SkillDef(
  id: 'tactical_probe',
  name: 'tactical_probe',
  description: 'tactical_probe',
  type: SkillType.normalAttack,
  powerMultiplier: 0,
  qiDelta: -1,
  cooldownSeconds: cooldownSeconds,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: '',
  source: SkillSource.special,
  targetType: TargetType.aoe,
  phase0aBehavior: Phase0aSkillBehavior(
    geometry: const Phase0aSkillGeometry(
      shape: Phase0aSkillGeometryShape.radial,
      anchor: Phase0aSkillGeometryAnchor.targetPoint,
      radius: 100,
    ),
    effects: const [
      Phase0aSkillEffect(
        type: Phase0aSkillEffectType.pull,
        destinationRadius: 50,
        controlTicks: 5,
      ),
    ],
  ),
);

void main() {
  test('战术技能冷却必须是有限非负秒数', () {
    for (final cooldown in <double>[
      double.nan,
      double.infinity,
      double.negativeInfinity,
      -0.1,
    ]) {
      expect(
        () => Phase0aTacticalSkillBinding(
          kind: Phase0aTacticalSkillKind.gather,
          slot: 'gather',
          skill: tacticalSkill(cooldown),
        ),
        throwsStateError,
        reason: 'cooldownSeconds=$cooldown',
      );
    }
  });

  test('零秒冷却保持合法并逐值透出', () {
    final binding = Phase0aTacticalSkillBinding(
      kind: Phase0aTacticalSkillKind.gather,
      slot: 'gather',
      skill: tacticalSkill(0),
    );

    expect(binding.cooldownSeconds, 0);
    expect(binding.controlTicks, 5);
  });
}
