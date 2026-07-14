import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/presentation/first_clear_showcase.dart';

/// 最小 BattleCharacter（沿 charge_transition_sfx_test 体例，补 teamSide 参数）。
BattleCharacter _c({
  int id = 1,
  int teamSide = 0,
  SkillDef? chargingSkill,
}) => BattleCharacter(
  characterId: id,
  name: 'c$id',
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
  availableSkills: const [],
  skillCooldowns: const {},
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: true,
  teamSide: teamSide,
  slotIndex: 0,
  chargingSkill: chargingSkill,
);

const _powerSkill = SkillDef(
  id: 'power_1',
  name: '崩山掌',
  description: 'd',
  type: SkillType.powerSkill,
  powerMultiplier: 1500,
  internalForceCost: 60,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: 'none',
);

const _normalSkill = SkillDef(
  id: 'normal_1',
  name: '劈砍',
  description: 'd',
  type: SkillType.normalAttack,
  powerMultiplier: 500,
  internalForceCost: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: 'none',
);

const _hit = AttackResult(
  finalDamage: 1500,
  mainDamage: 1500,
  quakeDamage: 0,
  isCritical: false,
  isDodged: false,
  schoolCounterMultiplier: 1.0,
  realmDiffAttackerMod: 1.0,
  realmDiffDefenderMod: 1.0,
  cultivationMultiplier: 1.0,
  criticalMultiplier: 1.0,
  defenseRate: 0.15,
  evasionRate: 0.05,
  appliedEffects: <String>[],
  formulaBreakdown: 'test',
);

/// 玩家(id=1,teamSide=0) vs 敌方(id=2,teamSide=1)。
BattleState _s({SkillDef? enemyCharging}) => BattleState.initial(
  leftTeam: [_c(id: 1, teamSide: 0)],
  rightTeam: [_c(id: 2, teamSide: 1, chargingSkill: enemyCharging)],
);

BattleAction _act({
  int actor = 1,
  SkillDef? skill,
  AttackResult? result,
  bool interrupted = false,
}) => BattleAction(
  tick: 1,
  actorId: actor,
  targetId: 2,
  skill: skill,
  attackResult: result,
  description: 'd',
  interrupted: interrupted,
);

void main() {
  group('consumeOpening', () {
    test('首次 true、此后恒 false（开局亮相整场一次）', () {
      final d = FirstClearShowcaseDirector();
      expect(d.consumeOpening(), isTrue);
      expect(d.consumeOpening(), isFalse);
      expect(d.consumeOpening(), isFalse);
    });
  });

  group('onAction · firstSkill', () {
    test('玩家首个非普攻真命中技能 → firstSkill，仅一次', () {
      final d = FirstClearShowcaseDirector();
      final s = _s();
      expect(
        d.onAction(_act(skill: _powerSkill, result: _hit), s),
        ShowcaseBeat.firstSkill,
      );
      expect(d.onAction(_act(skill: _powerSkill, result: _hit), s), isNull);
    });

    test('普攻不触发 firstSkill', () {
      final d = FirstClearShowcaseDirector();
      expect(
        d.onAction(_act(skill: _normalSkill, result: _hit), _s()),
        isNull,
      );
    });

    test('敌方技能不触发', () {
      final d = FirstClearShowcaseDirector();
      expect(
        d.onAction(_act(actor: 2, skill: _powerSkill, result: _hit), _s()),
        isNull,
      );
    });

    test('无 attackResult 的技能动作（如起手蓄力行）不触发', () {
      final d = FirstClearShowcaseDirector();
      expect(d.onAction(_act(skill: _powerSkill), _s()), isNull);
    });

    test('actor 不在场（找不到角色）不触发', () {
      final d = FirstClearShowcaseDirector();
      expect(
        d.onAction(_act(actor: 77, skill: _powerSkill, result: _hit), _s()),
        isNull,
      );
    });
  });

  group('onAction · interruptFlourish', () {
    test('玩家首次破招 → interruptFlourish，仅一次；不消耗 firstSkill', () {
      final d = FirstClearShowcaseDirector();
      final s = _s();
      expect(
        d.onAction(
          _act(skill: _powerSkill, result: _hit, interrupted: true),
          s,
        ),
        ShowcaseBeat.interruptFlourish,
      );
      // 第二次破招不再触发。
      expect(
        d.onAction(
          _act(skill: _powerSkill, result: _hit, interrupted: true),
          s,
        ),
        isNull,
      );
      // firstSkill 未被破招消耗，下一个普通技能仍触发。
      expect(
        d.onAction(_act(skill: _powerSkill, result: _hit), s),
        ShowcaseBeat.firstSkill,
      );
    });

    test('敌方破招（打断玩家蓄力）不触发', () {
      final d = FirstClearShowcaseDirector();
      expect(
        d.onAction(
          _act(actor: 2, skill: _powerSkill, result: _hit, interrupted: true),
          _s(),
        ),
        isNull,
      );
    });
  });

  group('consumeEnemyChargeCue', () {
    test('prev=null（开局）→ false', () {
      final d = FirstClearShowcaseDirector();
      expect(d.consumeEnemyChargeCue(null, _s()), isFalse);
    });

    test('敌方 chargingSkill null→非null 边沿 → true，整场仅一次', () {
      final d = FirstClearShowcaseDirector();
      final prev = _s();
      final next = _s(enemyCharging: _powerSkill);
      expect(d.consumeEnemyChargeCue(prev, next), isTrue);
      // 同类边沿再来（如第二次蓄力）不再触发。
      expect(d.consumeEnemyChargeCue(prev, next), isFalse);
    });

    test('无蓄力变化 → false（且不消费）', () {
      final d = FirstClearShowcaseDirector();
      expect(d.consumeEnemyChargeCue(_s(), _s()), isFalse);
      // 未消费:真边沿到来仍能触发。
      expect(
        d.consumeEnemyChargeCue(_s(), _s(enemyCharging: _powerSkill)),
        isTrue,
      );
    });

    test('玩家侧蓄力不触发（只看敌方 teamSide=1）', () {
      final d = FirstClearShowcaseDirector();
      final prev = BattleState.initial(
        leftTeam: [_c(id: 1, teamSide: 0)],
        rightTeam: [_c(id: 2, teamSide: 1)],
      );
      final next = BattleState.initial(
        leftTeam: [_c(id: 1, teamSide: 0, chargingSkill: _powerSkill)],
        rightTeam: [_c(id: 2, teamSide: 1)],
      );
      expect(d.consumeEnemyChargeCue(prev, next), isFalse);
    });
  });
}
