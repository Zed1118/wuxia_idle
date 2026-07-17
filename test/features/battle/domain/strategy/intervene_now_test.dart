import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';
import '../../../../support/test_data.dart';

void main() {
  setUpAll(() async {
    await loadTestGameRepository();
  });

  const power = SkillDef(
    id: 'skill_iv_power',
    name: '截脉手',
    description: '插队测强力技',
    type: SkillType.powerSkill,
    powerMultiplier: 1500,
    internalForceCost: 100,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );
  const normal = SkillDef(
    id: 'skill_iv_normal',
    name: '普攻',
    description: '插队测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );
  const powerB = SkillDef(
    id: 'skill_iv_power_b',
    name: '穿云手',
    description: '插队测第二强力技',
    type: SkillType.powerSkill,
    powerMultiplier: 1400,
    internalForceCost: 100,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );
  const interrupt = SkillDef(
    id: 'skill_iv_interrupt',
    name: '截气式',
    description: '插队测破招技',
    type: SkillType.powerSkill,
    powerMultiplier: 1200,
    internalForceCost: 100,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    canInterrupt: true,
    visualEffect: 'stub',
  );
  const foreignSkill = SkillDef(
    id: 'skill_iv_foreign',
    name: '无名秘式',
    description: '未装备技能守卫',
    type: SkillType.powerSkill,
    powerMultiplier: 1800,
    internalForceCost: 100,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter unit({
    required int charId,
    required int teamSide,
    required int slot,
    int ap = 0,
  }) => BattleCharacter(
    characterId: charId,
    name: '$charId',
    realmTier: RealmTier.yiLiu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    maxHp: 12000,
    currentHp: 12000,
    maxInternalForce: 2000,
    currentInternalForce: 2000,
    speed: 120,
    criticalRate: 0.0,
    evasionRate: 0.0,
    defenseRate: 0.1,
    totalEquipmentAttack: 700,
    mainCultivationLayer: CultivationLayer.daCheng,
    availableSkills: const <SkillDef>[power, powerB, normal],
    skillCooldowns: const {},
    activeBuffs: const [],
    actionPoint: ap,
    isAlive: true,
    teamSide: teamSide,
    slotIndex: slot,
  );

  test('AP 未满的玩家角色拖招 → 立即出手 + AP 归零 + 命中指定目标', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final state = BattleState.initial(
      leftTeam: [unit(charId: 1, teamSide: 0, slot: 0, ap: 300)],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );

    final after = strat.interveneNow(
      state,
      1,
      power,
      targetId: -1,
      n: n,
      rng: Random(7),
    );

    final acted = after.actionLog.where((a) => a.actorId == 1).toList();
    expect(acted, isNotEmpty, reason: '拖招应立即结算一次行动');
    expect(acted.last.skill?.id, 'skill_iv_power');
    expect(acted.last.targetId, -1);

    final actor = after.leftTeam.firstWhere((c) => c.characterId == 1);
    expect(actor.actionPoint, 0, reason: '预支语义:出手后 AP 归零');

    expect(after.pendingUltimates.containsKey(1), isFalse);
    expect(after.pendingTargets.containsKey(1), isFalse);
  });

  test('立即出手击倒目标时把击杀事实写入动作快照', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final fragileEnemy = unit(
      charId: -1,
      teamSide: 1,
      slot: 0,
    ).copyWith(currentHp: 1);
    final state = BattleState.initial(
      leftTeam: [unit(charId: 1, teamSide: 0, slot: 0, ap: 300)],
      rightTeam: [fragileEnemy],
    );

    final after = strat.interveneNow(
      state,
      1,
      power,
      targetId: -1,
      n: n,
      rng: Random(7),
    );

    expect(after.actionLog.last.defeatedTarget, isTrue);
    expect(after.rightTeam.single.isAlive, isFalse);
  });

  test('同角色插队后 AP 归零 → 第二招被拒且不消耗资源', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final state = BattleState.initial(
      leftTeam: [unit(charId: 1, teamSide: 0, slot: 0, ap: 300)],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );

    final first = strat.interveneNow(
      state,
      1,
      power,
      targetId: -1,
      n: n,
      rng: Random(7),
    );
    final beforeActor = first.leftTeam.first;
    final second = strat.interveneNow(
      first,
      1,
      powerB,
      targetId: -1,
      n: n,
      rng: Random(8),
    );

    expect(second.actionLog, hasLength(first.actionLog.length));
    expect(
      second.leftTeam.first.currentInternalForce,
      beforeActor.currentInternalForce,
    );
    expect(second.leftTeam.first.skillCooldowns, beforeActor.skillCooldowns);
    expect(second.leftTeam.first.actionPoint, 0);
  });

  test('同角色 AP 重新积累为正后 → 可再次预支插队', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final state = BattleState.initial(
      leftTeam: [unit(charId: 1, teamSide: 0, slot: 0, ap: 300)],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );
    final first = strat.interveneNow(
      state,
      1,
      power,
      targetId: -1,
      n: n,
      rng: Random(7),
    );
    final advanced = strat.stepOne(first, n, rng: Random(8));
    expect(advanced.actorQueue, isEmpty);
    expect(advanced.leftTeam.first.actionPoint, greaterThan(0));

    final second = strat.interveneNow(
      advanced,
      1,
      powerB,
      targetId: -1,
      n: n,
      rng: Random(9),
    );

    expect(second.actionLog, hasLength(first.actionLog.length + 1));
    expect(second.actionLog.last.skill?.id, powerB.id);
    expect(second.leftTeam.first.actionPoint, 0);
  });

  test('不同角色在同一 tick 边界仍可各自连续插队', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final state = BattleState.initial(
      leftTeam: [
        unit(charId: 1, teamSide: 0, slot: 0, ap: 300),
        unit(charId: 2, teamSide: 0, slot: 1, ap: 250),
      ],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );

    final first = strat.interveneNow(
      state,
      1,
      power,
      targetId: -1,
      n: n,
      rng: Random(7),
    );
    final second = strat.interveneNow(
      first,
      2,
      powerB,
      targetId: -1,
      n: n,
      rng: Random(8),
    );

    expect(
      second.actionLog.map((action) => action.actorId),
      containsAll([1, 2]),
    );
    expect(second.leftTeam[0].actionPoint, 0);
    expect(second.leftTeam[1].actionPoint, 0);
  });

  test('减耗后真气仅够有效耗气时仍可插队，扣气与同源公式一致', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final reduced = unit(
      charId: 1,
      teamSide: 0,
      slot: 0,
      ap: 300,
    ).copyWith(currentQi: 80, qiCostReductionPct: 0.20);
    final state = BattleState.initial(
      leftTeam: [reduced],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );

    final after = strat.interveneNow(
      state,
      1,
      power,
      targetId: -1,
      n: n,
      rng: Random(7),
    );

    expect(after.actionLog, isNotEmpty);
    expect(after.actionLog.last.skill?.id, power.id);
    expect(
      after.leftTeam.first.currentQi,
      n.combat.qi.schoolBonus,
      reason: '80 有效耗气扣清后，刚猛命中只回本次流派产气',
    );
  });

  test('已死角色拖招 → noop（state 不变）', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final dead = unit(
      charId: 1,
      teamSide: 0,
      slot: 0,
    ).copyWith(currentHp: 0, isAlive: false);
    final state = BattleState.initial(
      leftTeam: [dead],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );
    final after = strat.interveneNow(
      state,
      1,
      power,
      targetId: -1,
      n: n,
      rng: Random(7),
    );
    expect(after.actionLog, isEmpty);
  });

  test('普攻拖招 → noop(strategy 层防线,不抛 ArgumentError)', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final state = BattleState.initial(
      leftTeam: [unit(charId: 1, teamSide: 0, slot: 0, ap: 300)],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );
    final after = strat.interveneNow(
      state,
      1,
      normal,
      targetId: -1,
      n: n,
      rng: Random(7),
    );
    expect(after.actionLog, isEmpty, reason: '普攻不走插队,noop 不抛异常');
  });

  test('踉跄中的玩家角色拖招 → noop(不静默 fizzle)', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final staggered = unit(
      charId: 1,
      teamSide: 0,
      slot: 0,
      ap: 300,
    ).copyWith(staggerTicksRemaining: 2);
    final state = BattleState.initial(
      leftTeam: [staggered],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );
    final after = strat.interveneNow(
      state,
      1,
      power,
      targetId: -1,
      n: n,
      rng: Random(7),
    );
    expect(after.actionLog, isEmpty, reason: '踉跄中不接受插队');
    final actor = after.leftTeam.firstWhere((c) => c.characterId == 1);
    expect(actor.actionPoint, 300, reason: 'noop 不改 AP');
  });

  test('蓄力中的玩家角色拖招 → noop', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final charging = unit(
      charId: 1,
      teamSide: 0,
      slot: 0,
      ap: 300,
    ).copyWith(chargingSkill: power, chargeTicksRemaining: 2);
    final state = BattleState.initial(
      leftTeam: [charging],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );
    final after = strat.interveneNow(
      state,
      1,
      power,
      targetId: -1,
      n: n,
      rng: Random(7),
    );
    expect(after.actionLog, isEmpty, reason: '蓄力中不接受插队');
  });

  test('普通单体技指定受护法保护 Boss → noop 且不消耗资源', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final actor = unit(charId: 1, teamSide: 0, slot: 0, ap: 300);
    final boss = unit(charId: -1, teamSide: 1, slot: 0).copyWith(
      isBoss: true,
      enemyDefId: 'ward_boss',
      guardianWardMult: 0.15,
      guardianDefIds: const ['ward_guardian'],
    );
    final guardian = unit(
      charId: -2,
      teamSide: 1,
      slot: 1,
    ).copyWith(enemyDefId: 'ward_guardian');
    final state = BattleState.initial(
      leftTeam: [actor],
      rightTeam: [boss, guardian],
    );

    final after = strat.interveneNow(
      state,
      actor.characterId,
      power,
      targetId: boss.characterId,
      n: n,
      rng: Random(7),
    );

    expect(after.actionLog, isEmpty);
    expect(after.leftTeam.first.actionPoint, actor.actionPoint);
    expect(after.leftTeam.first.currentQi, actor.currentQi);
  });

  test('护法阵亡后普通单体技可重新指定 Boss', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final actor = unit(charId: 1, teamSide: 0, slot: 0, ap: 300);
    final boss = unit(charId: -1, teamSide: 1, slot: 0).copyWith(
      isBoss: true,
      enemyDefId: 'ward_boss',
      guardianWardMult: 0.15,
      guardianDefIds: const ['ward_guardian'],
    );
    final deadGuardian = unit(
      charId: -2,
      teamSide: 1,
      slot: 1,
    ).copyWith(enemyDefId: 'ward_guardian', currentHp: 0, isAlive: false);
    final state = BattleState.initial(
      leftTeam: [actor],
      rightTeam: [boss, deadGuardian],
    );

    final after = strat.interveneNow(
      state,
      actor.characterId,
      power,
      targetId: boss.characterId,
      n: n,
      rng: Random(7),
    );

    expect(after.actionLog.last.targetId, boss.characterId);
    expect(after.actionLog.last.skill?.id, power.id);
  });

  test('破招技仍可指定正在蓄力的受保护 Boss', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final actor = unit(
      charId: 1,
      teamSide: 0,
      slot: 0,
      ap: 300,
    ).copyWith(availableSkills: const [power, powerB, normal, interrupt]);
    final boss = unit(charId: -1, teamSide: 1, slot: 0).copyWith(
      isBoss: true,
      enemyDefId: 'ward_boss',
      guardianWardMult: 0.15,
      guardianDefIds: const ['ward_guardian'],
      chargingSkill: powerB,
      chargeTicksRemaining: 2,
    );
    final guardian = unit(
      charId: -2,
      teamSide: 1,
      slot: 1,
    ).copyWith(enemyDefId: 'ward_guardian');
    final state = BattleState.initial(
      leftTeam: [actor],
      rightTeam: [boss, guardian],
    );

    final after = strat.interveneNow(
      state,
      actor.characterId,
      interrupt,
      targetId: boss.characterId,
      n: n,
      rng: Random(7),
    );

    expect(after.actionLog.last.targetId, boss.characterId);
    expect(after.actionLog.last.skill?.id, interrupt.id);
  });

  test('真气不足的指定技能 → noop 而非静默改打其他招', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final actor = unit(
      charId: 1,
      teamSide: 0,
      slot: 0,
      ap: 300,
    ).copyWith(currentQi: 50);
    final state = BattleState.initial(
      leftTeam: [actor],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );

    final after = strat.interveneNow(
      state,
      actor.characterId,
      power,
      targetId: -1,
      n: n,
      rng: Random(7),
    );

    expect(after.actionLog, isEmpty);
    expect(after.leftTeam.first.actionPoint, actor.actionPoint);
    expect(after.leftTeam.first.currentQi, actor.currentQi);
  });

  test('冷却中的指定技能 → noop 而非静默改打其他招', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final actor = unit(
      charId: 1,
      teamSide: 0,
      slot: 0,
      ap: 300,
    ).copyWith(skillCooldowns: const {'skill_iv_power': 2});
    final state = BattleState.initial(
      leftTeam: [actor],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );

    final after = strat.interveneNow(
      state,
      actor.characterId,
      power,
      targetId: -1,
      n: n,
      rng: Random(7),
    );

    expect(after.actionLog, isEmpty);
    expect(after.leftTeam.first.actionPoint, actor.actionPoint);
    expect(after.leftTeam.first.skillCooldowns[power.id], 2);
  });

  test('角色未装备的指定技能 → noop', () {
    const strat = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final actor = unit(charId: 1, teamSide: 0, slot: 0, ap: 300);
    final state = BattleState.initial(
      leftTeam: [actor],
      rightTeam: [unit(charId: -1, teamSide: 1, slot: 0)],
    );

    final after = strat.interveneNow(
      state,
      actor.characterId,
      foreignSkill,
      targetId: -1,
      n: n,
      rng: Random(7),
    );

    expect(after.actionLog, isEmpty);
    expect(after.leftTeam.first.actionPoint, actor.actionPoint);
  });
}
