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

  // ───────────────────────────────────────────────────────────────────────
  // Task 8:破招 + 踉跄
  // ───────────────────────────────────────────────────────────────────────

  // 玩家破招技(canInterrupt powerSkill,命中 charging 的 Boss → 打断)。
  const playerBreaker = SkillDef(
    id: 'skill_p0_player_breaker',
    name: '破招式',
    description: 'P0 Task8 玩家破招技',
    type: SkillType.powerSkill,
    powerMultiplier: 1000,
    internalForceCost: 100,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    canInterrupt: true,
  );

  /// 测 C 用:左=玩家(高速先手,持破招技),右=Boss(已处于 charging)。
  BattleState makeStateBreakC() {
    const player = BattleCharacter(
      characterId: 1,
      name: '玩家',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 12000,
      currentHp: 12000,
      maxInternalForce: 10000,
      currentInternalForce: 10000,
      speed: 400,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 1500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: <SkillDef>[playerBreaker, playerNormal],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 0,
      slotIndex: 0,
    );
    // Boss 已处于 charging:chargingSkill != null,chargeTicksRemaining=2。
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
      chargingSkill: bossSignature,
      chargeTicksRemaining: 2,
    );
    return BattleState.initial(leftTeam: [player], rightTeam: [boss]);
  }

  test('测 C 破招:玩家 canInterrupt 技命中 charging Boss → 打断 + 踉跄 + 招牌技上CD',
      () {
    var s = makeStateBreakC();
    final rng = Random(7);
    // 玩家手动请求破招技,推进直到玩家完成一次行动(命中 Boss)。
    s = strategy.requestUltimate(s, 1, playerBreaker);
    final bossHpBefore = bossOf(s).currentHp;
    var guard = 0;
    while (guard < 50 && !s.isFinished) {
      s = strategy.tick(s, numbers, rng: rng);
      if (bossOf(s).currentHp < bossHpBefore) break; // 玩家命中过 Boss
      guard++;
    }
    final boss = bossOf(s);
    expect(boss.chargingSkill, isNull, reason: '破招后 Boss chargingSkill 清空');
    expect(boss.staggerTicksRemaining,
        numbers.combat.bossCharge.defaultStaggerTicks,
        reason: '破招后 Boss 进入踉跄 == defaultStaggerTicks');
    expect(boss.skillCooldowns.containsKey('skill_p0_boss_signature'), isTrue,
        reason: '招牌技被打断 → 进 CD');
  });

  /// 测 D/E 用:直接构造单 actor tick,Boss(踉跄)在场。
  /// 左=Boss(踉跄,先手),右=玩家(被动靶子,不出手以便只观察 Boss)。
  BattleState makeStateStaggerD() {
    // Boss 踉跄,speed 高先手。
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
      speed: 400,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 1500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: <SkillDef>[playerNormal],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 0,
      slotIndex: 0,
      isBoss: true,
      staggerTicksRemaining: 2,
    );
    const player = BattleCharacter(
      characterId: 1,
      name: '玩家',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 12000,
      currentHp: 12000,
      maxInternalForce: 10000,
      currentInternalForce: 0,
      speed: 1, // 极慢,Boss 先动若干次后才轮到玩家
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
      teamSide: 1,
      slotIndex: 0,
    );
    return BattleState.initial(leftTeam: [boss], rightTeam: [player]);
  }

  test('测 D 踉跄跳过:Boss 踉跄时行动 → 跳过(玩家不掉血)+ stagger 递减 2→1', () {
    var s = makeStateStaggerD();
    final rng = Random(7);
    final playerHpBefore = s.rightTeam.first.currentHp;
    // Boss speed=400,需累积 actionPoint 到 1000(3 tick)才行动一次 → 踉跄跳过。
    // 推进直到 Boss 第一次行动(staggerTicksRemaining 2→1)。
    var guard = 0;
    while (guard < 20 &&
        s.leftTeam.firstWhere((c) => c.characterId == -1).staggerTicksRemaining ==
            2) {
      s = strategy.tick(s, numbers, rng: rng);
      guard++;
    }
    final boss = s.leftTeam.firstWhere((c) => c.characterId == -1);
    final player = s.rightTeam.firstWhere((c) => c.characterId == 1);
    expect(player.currentHp, playerHpBefore,
        reason: '踉跄跳过本次行动,玩家不掉血(player speed=1,本窗口内也未轮到)');
    expect(boss.staggerTicksRemaining, 1,
        reason: '踉跄 tick 递减 2→1');
  });

  /// 测 E:Boss 作为防守方被普攻命中,对比踉跄(减防)vs 非踉跄 finalDamage。
  /// 左=玩家(攻),右=Boss(守)。一次 tick 内只让玩家行动(Boss 极慢)。
  BattleState makeStateDefendE({required int bossStagger}) {
    const player = BattleCharacter(
      characterId: 1,
      name: '玩家',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 12000,
      currentHp: 12000,
      maxInternalForce: 10000,
      currentInternalForce: 8000,
      speed: 400,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 1500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: <SkillDef>[playerNormal],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 0,
      slotIndex: 0,
    );
    final boss = BattleCharacter(
      characterId: -1,
      name: '青衫剑客',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 50000,
      currentHp: 50000,
      maxInternalForce: 10000,
      currentInternalForce: 10000,
      speed: 1, // 极慢,本 tick 不行动
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.30, // 有防御率,踉跄减防才有可观察差
      totalEquipmentAttack: 1500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const <SkillDef>[playerNormal],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: 0,
      isBoss: true,
      staggerTicksRemaining: bossStagger,
    );
    return BattleState.initial(leftTeam: [player], rightTeam: [boss]);
  }

  /// 推进 tick 直到 Boss 第一次被打掉血,返回那次掉血量。
  int firstDamageToBoss(BattleState s) {
    final rng = Random(1);
    var prev = s.rightTeam.firstWhere((c) => c.characterId == -1).currentHp;
    var guard = 0;
    while (guard < 50 && !s.isFinished) {
      s = strategy.tick(s, numbers, rng: rng);
      final hp = s.rightTeam.firstWhere((c) => c.characterId == -1).currentHp;
      if (hp < prev) return prev - hp;
      prev = hp;
      guard++;
    }
    return 0;
  }

  test('测 E 踉跄减防增伤:Boss 踉跄时被普攻命中,finalDamage 高于非踉跄', () {
    // 非踉跄(stagger=0)基线。
    final dmgNoStagger = firstDamageToBoss(makeStateDefendE(bossStagger: 0));
    // 踉跄(stagger>0)。
    final dmgStagger = firstDamageToBoss(makeStateDefendE(bossStagger: 2));

    expect(dmgNoStagger, greaterThan(0), reason: '基线伤害应 > 0');
    expect(dmgStagger, greaterThan(dmgNoStagger),
        reason: '踉跄减防 → finalDamage 应高于非踉跄 '
            '(非踉跄=$dmgNoStagger 踉跄=$dmgStagger)');
  });
}
