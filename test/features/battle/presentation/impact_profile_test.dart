import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/presentation/impact_profile.dart';
import 'package:wuxia_idle/shared/strings.dart';

SkillDef _skill({required SkillType type, TechniqueSchool? style}) => SkillDef(
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

AttackResult _result({bool crit = false, bool dodge = false}) => AttackResult(
      finalDamage: dodge ? 0 : 100,
      mainDamage: dodge ? 0 : 100,
      quakeDamage: 0,
      isCritical: crit,
      isDodged: dodge,
      schoolCounterMultiplier: 1.0,
      realmDiffAttackerMod: 1.0,
      realmDiffDefenderMod: 1.0,
      cultivationMultiplier: 1.0,
      criticalMultiplier: crit ? 1.5 : 1.0,
      defenseRate: 0.1,
      evasionRate: 0.0,
      appliedEffects: const [],
      formulaBreakdown: '',
    );

BattleAction _action({
  required SkillDef? skill,
  AttackResult? result,
  bool interrupted = false,
}) =>
    BattleAction(
      tick: 1,
      actorId: 1,
      targetId: 2,
      skill: skill,
      attackResult: result,
      description: 'test',
      interrupted: interrupted,
    );

const _cfg = ImpactFeedbackConfig(
  light: ImpactTierParams(hitStopMs: 60, shakeMagnitude: 3, flashStrength: 0.12),
  medium: ImpactTierParams(hitStopMs: 90, shakeMagnitude: 6, flashStrength: 0.20),
  heavy: ImpactTierParams(hitStopMs: 120, shakeMagnitude: 10, flashStrength: 0.30),
);

void main() {
  group('tier', () {
    test('普攻非暴击 → null', () {
      expect(
        impactProfileFor(
            _action(skill: _skill(type: SkillType.normalAttack), result: _result()),
            _cfg),
        isNull,
      );
    });
    test('暴击普攻 → light', () {
      final p = impactProfileFor(
          _action(skill: _skill(type: SkillType.normalAttack), result: _result(crit: true)),
          _cfg);
      expect(p!.tier, ImpactTier.light);
      expect(p.hitStopMs, 60);
    });
    test('强力技 → medium', () {
      final p = impactProfileFor(
          _action(
              skill: _skill(type: SkillType.powerSkill, style: TechniqueSchool.gangMeng),
              result: _result()),
          _cfg);
      expect(p!.tier, ImpactTier.medium);
      expect(p.hitStopMs, 90);
    });
    test('大招 → heavy, glyph null', () {
      final p = impactProfileFor(
          _action(skill: _skill(type: SkillType.ultimate), result: _result(crit: true)),
          _cfg);
      expect(p!.tier, ImpactTier.heavy);
      expect(p.glyph, isNull);
      expect(p.hitStopMs, 120);
    });
    test('闪避 → null', () {
      expect(
        impactProfileFor(
            _action(skill: _skill(type: SkillType.ultimate), result: _result(dodge: true)),
            _cfg),
        isNull,
      );
    });
    test('attackResult 空 → null', () {
      expect(
        impactProfileFor(_action(skill: _skill(type: SkillType.ultimate)), _cfg),
        isNull,
      );
    });
  });
  group('glyph', () {
    test('刚猛强力技 → 震', () {
      expect(
        impactProfileFor(
            _action(
                skill: _skill(type: SkillType.powerSkill, style: TechniqueSchool.gangMeng),
                result: _result()),
            _cfg)!
            .glyph,
        UiStrings.impactGlyphZhen,
      );
    });
    test('阴柔强力技 → 断', () {
      expect(
        impactProfileFor(
            _action(
                skill: _skill(type: SkillType.powerSkill, style: TechniqueSchool.yinRou),
                result: _result()),
            _cfg)!
            .glyph,
        UiStrings.impactGlyphDuan,
      );
    });
    test('灵巧/无流派 → 斩', () {
      expect(
        impactProfileFor(
            _action(
                skill: _skill(type: SkillType.powerSkill, style: TechniqueSchool.lingQiao),
                result: _result()),
            _cfg)!
            .glyph,
        UiStrings.impactGlyphZhan,
      );
    });
    test('破招强力技 → tier 在但 glyph null', () {
      final p = impactProfileFor(
          _action(
              skill: _skill(type: SkillType.powerSkill, style: TechniqueSchool.gangMeng),
              result: _result(),
              interrupted: true),
          _cfg);
      expect(p!.tier, ImpactTier.medium);
      expect(p.glyph, isNull);
    });
  });
}
