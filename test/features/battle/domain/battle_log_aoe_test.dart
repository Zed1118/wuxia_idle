import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_log.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';

const _aoe = SkillDef(
  id: 'report_aoe',
  name: '万钧裂空',
  description: '',
  type: SkillType.ultimate,
  powerMultiplier: 3000,
  internalForceCost: 500,
  cooldownTurns: 3,
  requiresManualTrigger: true,
  targetType: TargetType.aoe,
  visualEffect: '',
);
const _normal = SkillDef(
  id: 'report_normal',
  name: '直拳',
  description: '',
  type: SkillType.normalAttack,
  powerMultiplier: 500,
  internalForceCost: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: '',
);

const _hit = AttackResult(
  finalDamage: 800,
  mainDamage: 800,
  quakeDamage: 0,
  isCritical: false,
  isDodged: false,
  schoolCounterMultiplier: 1,
  realmDiffAttackerMod: 1,
  realmDiffDefenderMod: 1,
  cultivationMultiplier: 1,
  criticalMultiplier: 1,
  defenseRate: 0,
  evasionRate: 0,
  appliedEffects: [],
  formulaBreakdown: '',
);

const _crit = AttackResult(
  finalDamage: 1600,
  mainDamage: 1600,
  quakeDamage: 0,
  isCritical: true,
  isDodged: false,
  schoolCounterMultiplier: 1,
  realmDiffAttackerMod: 1,
  realmDiffDefenderMod: 1,
  cultivationMultiplier: 1,
  criticalMultiplier: 2,
  defenseRate: 0,
  evasionRate: 0,
  appliedEffects: [],
  formulaBreakdown: '',
);

BattleCharacter _character(int id, int side, int slot) => BattleCharacter(
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
  criticalRate: 0,
  evasionRate: 0,
  defenseRate: 0,
  totalEquipmentAttack: 100,
  mainCultivationLayer: CultivationLayer.chuKui,
  availableSkills: const [_aoe],
  skillCooldowns: const {},
  activeBuffs: const [],
  actionPoint: 0,
  isAlive: true,
  teamSide: side,
  slotIndex: slot,
);

BattleAction _action(int tick, int targetId, AttackResult result) =>
    BattleAction(
      tick: tick,
      actorId: 1,
      targetId: targetId,
      skill: _aoe,
      attackResult: result,
      description: 'aoe',
    );

BattleState _state(List<BattleAction> actions) => BattleState.initial(
  leftTeam: [_character(1, 0, 0)],
  rightTeam: [_character(11, 1, 0), _character(12, 1, 1), _character(13, 1, 2)],
).copyWith(actionLog: actions);

void main() {
  test('同拍三目标群攻在最近关键战报只占一行并保留组内暴击', () {
    final state = _state([
      _action(1, 11, _hit),
      _action(1, 12, _crit),
      _action(1, 13, _hit),
    ]);

    final recent = BattleLog.recentKeyActions(state);

    expect(recent, hasLength(1));
    expect(recent.single.targetId, 12);
    expect(recent.single.attackResult?.isCritical, isTrue);
  });

  test('不同 tick 的连续群攻仍分别占一行', () {
    final state = _state([
      _action(1, 11, _hit),
      _action(1, 12, _hit),
      _action(2, 11, _hit),
      _action(2, 12, _hit),
    ]);

    final recent = BattleLog.recentKeyActions(state);

    expect(recent, hasLength(2));
    expect(recent.map((action) => action.tick), [2, 1]);
  });

  test('目标后来阵亡不会把早先普通命中追溯成击杀', () {
    const earlierHit = BattleAction(
      tick: 1,
      actorId: 1,
      targetId: 11,
      skill: _normal,
      attackResult: _hit,
      description: 'earlier hit',
    );
    final base = _state(const [earlierHit]);
    final state = base.copyWith(
      rightTeam: [
        base.rightTeam[0].copyWith(currentHp: 0, isAlive: false),
        ...base.rightTeam.skip(1),
      ],
    );

    expect(BattleLog.isKeyAction(earlierHit, state), isFalse);
    expect(BattleLog.recentKeyActions(state), isEmpty);
    expect(BattleLog.formatAction(earlierHit, state), isNot(contains('击杀')));
    expect(
      BattleLog.formatActionCompact(earlierHit, state),
      isNot(contains('击杀')),
    );
  });

  test('致死动作仅凭动作快照进入关键战报并显示击杀', () {
    const killingHit = BattleAction(
      tick: 2,
      actorId: 1,
      targetId: 11,
      skill: _normal,
      attackResult: _hit,
      description: 'killing hit',
      defeatedTarget: true,
    );
    // 保持目标当前仍为存活，证明展示只读动作发生当刻的事实快照。
    final state = _state(const [killingHit]);

    expect(BattleLog.isKeyAction(killingHit, state), isTrue);
    expect(BattleLog.recentKeyActions(state), const [killingHit]);
    expect(BattleLog.formatAction(killingHit, state), contains('击杀'));
    expect(BattleLog.formatActionCompact(killingHit, state), contains('击杀'));
  });
}
