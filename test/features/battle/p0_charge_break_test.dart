import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'dart:io';

/// P0 破招 Task 7:Boss 蓄力状态机(起手 / 进行 / 触发招牌技)。
///
/// 1v1:左=玩家(高速先手,普攻骚扰),右=Boss(chargeSkillId=招牌 powerSkill)。
///   - 起手蓄力:Boss 第一次行动 → chargingSkill!=null,chargeTicksRemaining==3,
///     本 tick 玩家不掉血(蓄力不出伤)。
///   - 蓄力递减:Boss 后续行动 chargeTicksRemaining 3→2→1。
///   - 蓄力满触发:蓄力满后 Boss 行动 → 招牌技命中玩家(玩家 currentHp 下降),
///     Boss chargingSkill 清空。
void main() {
  late NumbersConfig numbers;
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
    numbers = GameRepository.instance.numbers;
  });

  // Boss 招牌技(powerSkill,内力够 / CD0 → AI 第一选)。
  const bossSignature = SkillDef(
    id: 'skill_p0_boss_signature',
    name: '裂石掌',
    description: 'P0 Task7 Boss 招牌技',
    type: SkillType.powerSkill,
    powerMultiplier: 3000,
    internalForceCost: 100,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // 玩家普攻(低伤,确保不会在蓄力满前打死 Boss)。
  const playerNormal = SkillDef(
    id: 'skill_p0_player_normal',
    name: '普攻',
    description: 'P0 Task7 玩家普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 50,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  /// 左=玩家(高速先手),右=Boss(慢,带 chargeSkillId)。
  BattleState makeState() {
    const player = BattleCharacter(
      characterId: 1,
      name: '玩家',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 12000,
      currentHp: 12000,
      maxInternalForce: 10000,
      // 内力 0 + 装备攻击 0 → 普攻基础伤害仅来自倍率 50,
      // 确保玩家无法在 Boss 蓄力满前打死 50000 HP Boss(只验状态机)。
      currentInternalForce: 0,
      speed: 400,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.chuKui,
      availableSkills: <SkillDef>[playerNormal],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 0,
      slotIndex: 0,
    );
    const boss = BattleCharacter(
      characterId: -1,
      name: '青衫剑客',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 50000,
      currentHp: 50000,
      maxInternalForce: 10000,
      currentInternalForce: 10000,
      speed: 100,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 1500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: <SkillDef>[bossSignature, playerNormal],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: 0,
      isBoss: true,
      chargeSkillId: 'skill_p0_boss_signature',
    );
    return BattleState.initial(leftTeam: [player], rightTeam: [boss]);
  }

  const strategy = DefaultGroundStrategy();

  BattleCharacter bossOf(BattleState s) =>
      s.rightTeam.firstWhere((c) => c.characterId == -1);
  BattleCharacter playerOf(BattleState s) =>
      s.leftTeam.firstWhere((c) => c.characterId == 1);

  /// 推进 tick 直到 Boss 行动过(actionPoint 被消费,或 charging 状态变化)。
  /// 返回 Boss 完成第 [count] 次行动后的 state。
  BattleState advanceUntilBossActs(BattleState s, int count) {
    final rng = Random(42);
    var acts = 0;
    var prevTickActed = false;
    // 用蓄力计数变化 / chargingSkill 出现来判断 Boss 行动。
    var lastChargeTicks = bossOf(s).chargeTicksRemaining;
    var lastCharging = bossOf(s).chargingSkill != null;
    while (acts < count && !s.isFinished) {
      final before = bossOf(s);
      final beforeAp = before.actionPoint;
      s = strategy.tick(s, numbers, rng: rng);
      final after = bossOf(s);
      // Boss 行动判定:actionPoint 减少 1000(蓄力/触发都消费 ap)或状态变化。
      final acted = after.actionPoint < beforeAp ||
          after.chargingSkill != lastCharging ||
          after.chargeTicksRemaining != lastChargeTicks;
      if (acted) {
        acts++;
        lastChargeTicks = after.chargeTicksRemaining;
        lastCharging = after.chargingSkill != null;
      }
      prevTickActed = acted;
    }
    expect(prevTickActed || s.isFinished, isTrue);
    return s;
  }

  test('起手蓄力:Boss 第一次行动进入 charging,玩家不掉血', () {
    var s = makeState();
    final rng = Random(42);
    // 推进直到 Boss 第一次行动(chargingSkill 出现)。
    while (bossOf(s).chargingSkill == null && !s.isFinished) {
      s = strategy.tick(s, numbers, rng: rng);
    }
    final boss = bossOf(s);
    expect(boss.chargingSkill, isNotNull,
        reason: 'Boss 起手应进入蓄力');
    expect(boss.chargingSkill!.id, 'skill_p0_boss_signature');
    expect(boss.chargeTicksRemaining,
        numbers.combat.bossCharge.defaultChargeTicks,
        reason: '蓄力剩余 tick == defaultChargeTicks');
    // 蓄力起手本身不出伤:此时玩家 HP 应仍为满(玩家普攻只打 Boss,
    // Boss 蓄力不还手)。
    expect(playerOf(s).currentHp, 12000,
        reason: '蓄力起手 tick Boss 不出伤,玩家满血');
  });

  test('蓄力递减:Boss 后续行动 chargeTicksRemaining 3→2→1', () {
    var s = makeState();
    final rng = Random(42);
    // 起手蓄力。
    while (bossOf(s).chargingSkill == null && !s.isFinished) {
      s = strategy.tick(s, numbers, rng: rng);
    }
    expect(bossOf(s).chargeTicksRemaining, 3);

    // 记录每次 Boss 行动后 chargeTicksRemaining 序列。
    final seq = <int>[3];
    var lastTicks = 3;
    while (bossOf(s).chargingSkill != null &&
        bossOf(s).chargeTicksRemaining > 0 &&
        !s.isFinished) {
      s = strategy.tick(s, numbers, rng: rng);
      final t = bossOf(s).chargeTicksRemaining;
      if (bossOf(s).chargingSkill != null && t != lastTicks) {
        seq.add(t);
        lastTicks = t;
      }
      if (bossOf(s).chargingSkill == null) break;
    }
    // 递减序列应为 3,2,1。
    expect(seq, [3, 2, 1], reason: '蓄力 tick 应每次行动 -1');
  });

  test('蓄力满触发:Boss 招牌技命中玩家,charging 清空', () {
    var s = makeState();
    final rng = Random(42);
    final hpBefore = playerOf(s).currentHp;
    // 推进直到 Boss 蓄力清空(触发了招牌技)。
    var guard = 0;
    while (guard < 500 && !s.isFinished) {
      s = strategy.tick(s, numbers, rng: rng);
      final boss = bossOf(s);
      // charging 起手后又清空 => 触发完成。
      if (boss.chargingSkill == null &&
          boss.chargeTicksRemaining == 0 &&
          playerOf(s).currentHp < hpBefore) {
        break;
      }
      guard++;
    }
    expect(playerOf(s).currentHp, lessThan(hpBefore),
        reason: '蓄力满 Boss 招牌技应命中玩家,玩家掉血');
    expect(bossOf(s).chargingSkill, isNull,
        reason: '招牌技放出后 charging 清空');
    expect(bossOf(s).chargeTicksRemaining, 0);
  });
}
