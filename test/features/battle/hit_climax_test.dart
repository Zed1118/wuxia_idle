// 断言 hitClimaxFor 对 action+state 派生命中峰值类型（特写触发源）。
// 沿 impact_profile_test.dart 体例，复用相同 fixture 构造器。
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/presentation/impact_profile.dart';

// ── Fixture builders ──────────────────────────────────────────────────────────

SkillDef _skill({required SkillType type}) => SkillDef(
      id: 'test_skill',
      name: '测试招',
      description: '测试',
      type: type,
      powerMultiplier: 500,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      visualEffect: 'none',
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
}) =>
    BattleAction(
      tick: 1,
      actorId: 1,
      targetId: 2,
      skill: skill,
      attackResult: result,
      description: 'test',
    );

/// targetAlive=true → 目标还活着；false → 已死亡（击杀检测）。
BattleState _state({bool targetAlive = true}) {
  const actor = BattleCharacter(
    characterId: 1,
    name: 'actor',
    realmTier: RealmTier.sanLiu,
    realmLayer: RealmLayer.yuanShu,
    school: TechniqueSchool.gangMeng,
    maxHp: 1000,
    currentHp: 1000,
    maxInternalForce: 500,
    currentInternalForce: 500,
    speed: 100,
    criticalRate: 0.0,
    evasionRate: 0.0,
    defenseRate: 0.1,
    totalEquipmentAttack: 0,
    mainCultivationLayer: CultivationLayer.daCheng,
    availableSkills: [],
    skillCooldowns: {},
    activeBuffs: [],
    actionPoint: 0,
    isAlive: true,
    teamSide: 0,
    slotIndex: 0,
  );
  final target = BattleCharacter(
    characterId: 2,
    name: 'target',
    realmTier: RealmTier.sanLiu,
    realmLayer: RealmLayer.yuanShu,
    school: TechniqueSchool.gangMeng,
    maxHp: 1000,
    currentHp: targetAlive ? 100 : 0,
    maxInternalForce: 500,
    currentInternalForce: 500,
    speed: 100,
    criticalRate: 0.0,
    evasionRate: 0.0,
    defenseRate: 0.1,
    totalEquipmentAttack: 0,
    mainCultivationLayer: CultivationLayer.daCheng,
    availableSkills: const [],
    skillCooldowns: const {},
    activeBuffs: const [],
    actionPoint: 0,
    isAlive: targetAlive,
    teamSide: 1,
    slotIndex: 0,
  );
  return BattleState(
    leftTeam: [actor],
    rightTeam: [target],
    tick: 1,
    result: null,
    actionLog: const [],
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('hitClimaxFor', () {
    test('1. 大招+暴击 → ultimateCrit', () {
      expect(
        hitClimaxFor(
          _action(skill: _skill(type: SkillType.ultimate), result: _result(crit: true)),
          _state(),
        ),
        HitClimax.ultimateCrit,
      );
    });

    test('2. 普攻命中使目标 isAlive=false → kill', () {
      expect(
        hitClimaxFor(
          _action(skill: _skill(type: SkillType.normalAttack), result: _result()),
          _state(targetAlive: false),
        ),
        HitClimax.kill,
      );
    });

    test('3. 大招暴击且击杀目标 → ultimateCrit (优先级更高)', () {
      expect(
        hitClimaxFor(
          _action(skill: _skill(type: SkillType.ultimate), result: _result(crit: true)),
          _state(targetAlive: false),
        ),
        HitClimax.ultimateCrit,
      );
    });

    test('4. 普通命中 非暴击 非击杀 → none', () {
      expect(
        hitClimaxFor(
          _action(skill: _skill(type: SkillType.normalAttack), result: _result()),
          _state(),
        ),
        HitClimax.none,
      );
    });

    test('5. 大招 非暴击 → none (只有暴击大招才特写)', () {
      expect(
        hitClimaxFor(
          _action(skill: _skill(type: SkillType.ultimate), result: _result()),
          _state(),
        ),
        HitClimax.none,
      );
    });

    test('6. 闪避 → none', () {
      expect(
        hitClimaxFor(
          _action(
            skill: _skill(type: SkillType.ultimate),
            result: _result(dodge: true),
          ),
          _state(),
        ),
        HitClimax.none,
      );
    });
  });
}
