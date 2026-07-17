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
}
