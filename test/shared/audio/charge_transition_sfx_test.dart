import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';

/// 最小 BattleCharacter（沿 battle_character_charge_test 体例）。
BattleCharacter _c({
  int id = 1,
  SkillDef? chargingSkill,
  int staggerTicksRemaining = 0,
}) =>
    BattleCharacter(
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
      teamSide: 1,
      slotIndex: 0,
      chargingSkill: chargingSkill,
      staggerTicksRemaining: staggerTicksRemaining,
    );

const _skill = SkillDef(
  id: 'boss_signature',
  name: '招牌技',
  description: 'd',
  type: SkillType.ultimate,
  powerMultiplier: 5000,
  internalForceCost: 200,
  cooldownTurns: 4,
  requiresManualTrigger: false,
  visualEffect: 'none',
);

/// 单角色右队 state（左队放一个无关玩家不参与转移）。
BattleState _state(BattleCharacter enemy) => BattleState.initial(
      leftTeam: [_c(id: 99)],
      rightTeam: [enemy],
    );

void main() {
  test('prev=null（开局）→ 空', () {
    expect(chargeTransitionSfx(null, _state(_c())), isEmpty);
  });

  test('起手蓄力（chargingSkill null→非null）→ [battleChargeStart]', () {
    final prev = _state(_c());
    final next = _state(_c(chargingSkill: _skill));
    expect(chargeTransitionSfx(prev, next), [SfxId.battleChargeStart]);
  });

  test('破招（chargingSkill 非null→null + staggerTicks 0→2）→ [battleInterrupt]',
      () {
    final prev = _state(_c(chargingSkill: _skill, staggerTicksRemaining: 0));
    final next = _state(_c(chargingSkill: null, staggerTicksRemaining: 2));
    expect(chargeTransitionSfx(prev, next), [SfxId.battleInterrupt]);
  });

  test('踉跄跳过（staggerTicks 2→1）→ [battleStagger]', () {
    final prev = _state(_c(staggerTicksRemaining: 2));
    final next = _state(_c(staggerTicksRemaining: 1));
    expect(chargeTransitionSfx(prev, next), [SfxId.battleStagger]);
  });

  test('蓄力满正常释放（chargingSkill 非null→null 但 staggerTicks 不变 0→0）→ 空', () {
    final prev = _state(_c(chargingSkill: _skill, staggerTicksRemaining: 0));
    final next = _state(_c(chargingSkill: null, staggerTicksRemaining: 0));
    expect(chargeTransitionSfx(prev, next), isEmpty);
  });

  test('无变化 → 空', () {
    final prev = _state(_c());
    final next = _state(_c());
    expect(chargeTransitionSfx(prev, next), isEmpty);
  });
}
