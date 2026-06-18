// 第六阶段：开窗题字纯函数测试。
// 断言 impactProfileFor 对 openedBreakWindow==true 的动作返回「破绽」字形；
// 对 interrupted==true 的动作仍返回 null glyph（「破!」走 ultimateCaption，不走 impactGlyph）。
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/presentation/impact_profile.dart';
import 'package:wuxia_idle/shared/strings.dart';

SkillDef _skill({
  SkillType type = SkillType.powerSkill,
  TechniqueSchool? style,
}) => SkillDef(
      id: 'test_skill',
      name: '测试招',
      description: '测试',
      type: type,
      powerMultiplier: 500,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      visualEffect: 'none',
      style: style,
    );

AttackResult _result() => const AttackResult(
      finalDamage: 500,
      mainDamage: 500,
      quakeDamage: 0,
      isCritical: false,
      isDodged: false,
      schoolCounterMultiplier: 1.0,
      realmDiffAttackerMod: 1.0,
      realmDiffDefenderMod: 1.0,
      cultivationMultiplier: 1.0,
      criticalMultiplier: 1.0,
      defenseRate: 0.1,
      evasionRate: 0.0,
      appliedEffects: [],
      formulaBreakdown: '',
    );

BattleAction _breakWindowAction() => BattleAction(
      tick: 1,
      actorId: 1,
      targetId: 2,
      skill: _skill(type: SkillType.powerSkill, style: TechniqueSchool.gangMeng),
      attackResult: _result(),
      description: 'test',
      openedBreakWindow: true,
    );

BattleAction _interruptedAction() => BattleAction(
      tick: 1,
      actorId: 1,
      targetId: 2,
      skill: _skill(type: SkillType.powerSkill, style: TechniqueSchool.gangMeng),
      attackResult: _result(),
      description: 'test',
      interrupted: true,
    );

BattleAction _normalPowerAction() => BattleAction(
      tick: 1,
      actorId: 1,
      targetId: 2,
      skill: _skill(type: SkillType.powerSkill, style: TechniqueSchool.gangMeng),
      attackResult: _result(),
      description: 'test',
    );

const _cfg = ImpactFeedbackConfig(
  light: ImpactTierParams(hitStopMs: 60, shakeMagnitude: 3, flashStrength: 0.12),
  medium: ImpactTierParams(hitStopMs: 90, shakeMagnitude: 6, flashStrength: 0.20),
  heavy: ImpactTierParams(hitStopMs: 120, shakeMagnitude: 10, flashStrength: 0.30),
);

void main() {
  group('break_window glyph', () {
    test('openedBreakWindow==true → glyph 为 impactGlyphBreakWindow(「破绽」)', () {
      final p = impactProfileFor(_breakWindowAction(), _cfg);
      expect(p, isNotNull);
      expect(p!.glyph, UiStrings.impactGlyphBreakWindow);
    });

    test('openedBreakWindow==true → tier 仍由 skillType 决定（强力技 medium）', () {
      final p = impactProfileFor(_breakWindowAction(), _cfg);
      expect(p!.tier, ImpactTier.medium);
    });

    test('interrupted==true → glyph 为 null（「破!」走 ultimateCaption 不走 impactGlyph）', () {
      final p = impactProfileFor(_interruptedAction(), _cfg);
      expect(p, isNotNull);
      expect(p!.glyph, isNull,
          reason: '破招动作的「破!」由 _ultimateCaptionKey 弹出,impactGlyph 不应重叠');
    });

    test('普通强力技（无 flag）→ glyph 为流派字（震）', () {
      final p = impactProfileFor(_normalPowerAction(), _cfg);
      expect(p!.glyph, UiStrings.impactGlyphZhen);
    });
  });
}
