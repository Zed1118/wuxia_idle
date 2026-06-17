import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_ai.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart' show RealmUtils;
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

/// P0 破招 Task 11:stage_02_05「巷中夜雨」端到端验收。
///
/// 三测一文件,证明 P0 破招机制在生产 stage_02_05 上闭环:
///   测 1(托管 parity):加载生产 stage_02_05 + 真 player build + 真 enemyTeam →
///     `DefaultGroundStrategy().runToEnd` 多 seed 多数通关。青衫剑客 powerSkill
///     改蓄力后 Boss DPS 下降,托管(无破招)仍应能解 → leftWin。
///   测 2(手动破招路径):1v1 玩家(内联构造,含 canInterrupt powerSkill)vs Boss
///     (chargeSkillId 指向其 powerSkill)。推进到 Boss charging → requestUltimate
///     破招技 → 断言 Boss staggered + 招牌技该 tick 未命中玩家。
///   测 3(targeting):玩家 + 3 敌(Boss charging + 两小怪血更低)→ canInterrupt
///     技经 BattleAI.decide → targetId == 蓄力 Boss,不是血最低小怪。
///
/// 测 1 复用 balance_simulator 的「真 build player + production enemyTeam +
/// runToEnd」体例;测 2/3 复用 p0_charge_break_test / battle_ai_interrupt_test
/// 的内联 BattleCharacter 构造体例。
void main() {
  late GameRepository repo;
  late NumbersConfig numbers;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    numbers = repo.numbers;
  });

  const strategy = DefaultGroundStrategy();

  // ───────────────────────────────────────────────────────────────────────
  // 测 1:托管 parity — 生产 stage_02_05 真战斗多 seed 多数通关
  // ───────────────────────────────────────────────────────────────────────

  test('测 1 托管 parity:生产 stage_02_05 + 真 build → 多 seed 多数 leftWin', () {
    final stage = repo.getStage('stage_02_05');
    expect(stage.isBossStage, isTrue, reason: 'stage_02_05 是章末 Boss 关');
    expect(stage.requiredRealm, RealmTier.sanLiu);
    // 青衫剑客招牌技改蓄力(stages.yaml chargeSkillId 接线)。
    final boss = StageBattleSetup.buildEnemyTeam(stage.enemyTeam)
        .firstWhere((e) => e.name == '青衫剑客');
    expect(boss.chargeSkillId, 'skill_qingshan_qingfeng',
        reason: 'Boss 招牌大招「青锋绝」已接蓄力(P0.5 stage 接线)');

    // 玩家 on-level(sanLiu)真 build × ceiling 剖面(活跃玩家配装)→ 托管能解。
    // 多 seed 跑,统计通关数:目的是证明托管能解,不是 100% 必胜。
    const seeds = [1, 7, 13, 42, 99, 123, 777, 2024];
    var wins = 0;
    final outcomes = <String>[];
    for (final seed in seeds) {
      final players = [
        _buildRealPlayer(repo, RealmTier.sanLiu, slot: 0, name: '玩家', isFounder: true),
        _buildRealPlayer(repo, RealmTier.sanLiu, slot: 1, name: '徒弟一', isFounder: false),
        _buildRealPlayer(repo, RealmTier.sanLiu, slot: 2, name: '徒弟二', isFounder: false),
      ];
      final enemies = StageBattleSetup.buildEnemyTeam(stage.enemyTeam);
      final initial =
          BattleState.initial(leftTeam: players, rightTeam: enemies);
      final terminal = strategy.runToEnd(initial, numbers,
          maxTicks: 1000, rng: Random(seed));
      outcomes.add('seed=$seed → ${terminal.result?.name ?? "timeout"}');
      if (terminal.result == BattleResult.leftWin) wins++;
    }

    // 多数通关(> 半数)即证明托管能独立解 stage_02_05。
    expect(
      wins,
      greaterThan(seeds.length ~/ 2),
      reason: '托管(无破招)应多数通关 stage_02_05;'
          'wins=$wins/${seeds.length}\n${outcomes.join("\n")}',
    );
  });

  // ───────────────────────────────────────────────────────────────────────
  // 测 2/3 共用内联 stub 技能(体例同 p0_charge_break_test / battle_ai_interrupt_test)
  // ───────────────────────────────────────────────────────────────────────

  // Boss 招牌技(powerSkill · Boss chargeSkillId 指向它 · 蓄力满命中重伤)。
  const bossSignature = SkillDef(
    id: 'skill_p0_e2e_boss_signature',
    name: '裂石掌',
    description: 'P0 e2e Boss 招牌蓄力技',
    type: SkillType.powerSkill,
    powerMultiplier: 3000,
    internalForceCost: 100,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // 玩家破招技(canInterrupt + saveForInterrupt powerSkill)。
  const playerBreaker = SkillDef(
    id: 'skill_p0_e2e_player_breaker',
    name: '破招式',
    description: 'P0 e2e 玩家破招技',
    type: SkillType.powerSkill,
    powerMultiplier: 1000,
    internalForceCost: 100,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    canInterrupt: true,
    aiUsePolicy: AiUsePolicy.saveForInterrupt,
  );

  // 玩家普通强力技(normal · 倍率更高 · 无人蓄力时 AI 优先它)。
  const playerNormalPower = SkillDef(
    id: 'skill_p0_e2e_player_normal_power',
    name: '普通强力技',
    description: 'P0 e2e normal powerSkill',
    type: SkillType.powerSkill,
    powerMultiplier: 2500,
    internalForceCost: 100,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    aiUsePolicy: AiUsePolicy.normal,
  );

  // 玩家普攻(兜底)。
  const playerNormal = SkillDef(
    id: 'skill_p0_e2e_player_normal',
    name: '普攻',
    description: 'P0 e2e 玩家普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 50,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // ───────────────────────────────────────────────────────────────────────
  // 测 2:手动破招路径 — requestUltimate 破招技打断 charging Boss
  // ───────────────────────────────────────────────────────────────────────

  test('测 2 手动破招:requestUltimate 破招技命中 charging Boss → staggered + 招牌技未命中玩家',
      () {
    // 1v1:玩家(高速先手,含破招技)vs Boss(chargeSkillId 指向 bossSignature)。
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
      chargeSkillId: 'skill_p0_e2e_boss_signature',
    );

    var s = BattleState.initial(leftTeam: [player], rightTeam: [boss]);
    final rng = Random(7);
    BattleCharacter bossOf(BattleState st) =>
        st.rightTeam.firstWhere((c) => c.characterId == -1);
    BattleCharacter playerOf(BattleState st) =>
        st.leftTeam.firstWhere((c) => c.characterId == 1);

    // 推进到 Boss 进入 charging(招牌技起手蓄力,本 tick 不出伤)。
    var guard = 0;
    while (bossOf(s).chargingSkill == null && !s.isFinished && guard < 200) {
      s = strategy.tick(s, numbers, rng: rng);
      guard++;
    }
    expect(bossOf(s).chargingSkill, isNotNull, reason: 'Boss 应进入蓄力');
    expect(bossOf(s).chargingSkill!.id, 'skill_p0_e2e_boss_signature');

    final playerHpBeforeBreak = playerOf(s).currentHp;
    final bossHpBeforeBreak = bossOf(s).currentHp;

    // 玩家手动请求破招技,推进直到玩家完成那次行动(命中 Boss → 掉血)。
    s = strategy.requestUltimate(s, 1, playerBreaker);
    guard = 0;
    while (guard < 50 && !s.isFinished) {
      s = strategy.tick(s, numbers, rng: rng);
      if (bossOf(s).currentHp < bossHpBeforeBreak) break; // 破招命中过 Boss
      guard++;
    }

    final bossAfter = bossOf(s);
    // 机制断言:Boss 被打断 → 踉跄 + 蓄力清空 + 招牌技进 CD。
    expect(bossAfter.chargingSkill, isNull, reason: '破招后 Boss 蓄力清空');
    expect(bossAfter.staggerTicksRemaining,
        numbers.combat.bossCharge.defaultStaggerTicks,
        reason: '破招后 Boss 进入踉跄(staggerTicksRemaining > 0)');
    expect(bossAfter.staggerTicksRemaining, greaterThan(0));
    expect(bossAfter.skillCooldowns.containsKey('skill_p0_e2e_boss_signature'),
        isTrue,
        reason: '招牌技被打断 → 进 CD,未在该 tick 命中玩家');
    // 招牌技未命中玩家:玩家没掉那一大笔(3000 倍率 ≈ 重伤)。破招窗口内玩家血量
    // 不因招牌技下降(允许等于;关键是没吃到招牌大伤)。
    expect(playerOf(s).currentHp, greaterThanOrEqualTo(playerHpBeforeBreak),
        reason: '破招拦下招牌技,玩家未吃招牌技重伤(currentHp 未下降)');
  });

  // ───────────────────────────────────────────────────────────────────────
  // 测 3:targeting — 破招技锁定蓄力 Boss,不挑血最低小怪
  // ───────────────────────────────────────────────────────────────────────

  test('测 3 targeting:3 敌(Boss charging + 两小怪血更低)→ canInterrupt 技命中 Boss',
      () {
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
      speed: 200,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 1500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: <SkillDef>[playerBreaker, playerNormalPower, playerNormal],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 0,
      slotIndex: 0,
    );

    BattleCharacter enemy({
      required int charId,
      required int slot,
      required int hp,
      bool boss = false,
      SkillDef? charging,
    }) =>
        BattleCharacter(
          characterId: charId,
          name: boss ? '青衫剑客' : '小怪$charId',
          realmTier: RealmTier.yiLiu,
          realmLayer: RealmLayer.qiMeng,
          school: TechniqueSchool.gangMeng,
          maxHp: 12000,
          currentHp: hp,
          maxInternalForce: 10000,
          currentInternalForce: 10000,
          speed: 100,
          criticalRate: 0.0,
          evasionRate: 0.0,
          defenseRate: 0.0,
          totalEquipmentAttack: 1500,
          mainCultivationLayer: CultivationLayer.daCheng,
          availableSkills: const <SkillDef>[],
          skillCooldowns: const {},
          activeBuffs: const [],
          actionPoint: 0,
          isAlive: true,
          teamSide: 1,
          slotIndex: slot,
          isBoss: boss,
          chargingSkill: charging,
          chargeTicksRemaining: charging != null ? 2 : 0,
        );

    // Boss(charId=-1)血更高 + charging;两小怪(-2/-3)血更低不蓄力。
    final boss = enemy(charId: -1, slot: 0, hp: 11000, boss: true, charging: bossSignature);
    final mobLow1 = enemy(charId: -2, slot: 1, hp: 2000);
    final mobLow2 = enemy(charId: -3, slot: 2, hp: 1500);
    final state = BattleState.initial(
      leftTeam: [player],
      rightTeam: [boss, mobLow1, mobLow2],
    );

    final (skill, targetIds) = BattleAI.decide(player, state, numbers);

    expect(skill.canInterrupt, isTrue,
        reason: '对面有人蓄力 + 有 saveForInterrupt 破招技 → AI 选破招');
    expect(skill.id, playerBreaker.id);
    expect(
      targetIds,
      [boss.characterId],
      reason: '破招技应锁定蓄力 Boss(-1),不挑血最低小怪(-3 血 1500 最低)',
    );
  });
}

/// 测 1 玩家代表 build(裁剪自 balance_simulator `_buildRealPlayer` ceiling 剖面):
/// 走生产 [BattleCharacter.fromCharacter] derived_stats 路径,tier-cap 真装备 +
/// tier-cap 主修心法。slot 0 = 祖师(isFounder · 享 founder buff),1-2 = 弟子。
BattleCharacter _buildRealPlayer(
  GameRepository repo,
  RealmTier tier, {
  required int slot,
  required String name,
  required bool isFounder,
}) {
  const layer = RealmLayer.huaJing; // 中高层(沿 balance_sim 体例)
  const school = TechniqueSchool.gangMeng;
  final numbers = repo.numbers;
  final realmDef = repo.getRealm(tier, layer);
  final enhanceLevel = (realmDef.absoluteLevel * 0.5).round(); // ½ 强化(ceiling)
  const battleCount = 400; // 默契段 ×1.20(ceiling)

  // tier-cap 真装备(weapon/armor/accessory · production equipmentDefs midpoint)。
  final eqTierCap = RealmUtils.equipmentTierCapOf(tier);
  final equipped = <Equipment>[];
  for (final wantSlot in [
    EquipmentSlot.weapon,
    EquipmentSlot.armor,
    EquipmentSlot.accessory,
  ]) {
    final defs = repo.equipmentDefs.values;
    final EquipmentDef def = defs.firstWhere(
      (d) => d.tier == eqTierCap && d.slot == wantSlot,
      orElse: () => defs.firstWhere((d) => d.slot == wantSlot),
    );
    equipped.add(Equipment.create(
      defId: def.id,
      tier: def.tier,
      slot: def.slot,
      obtainedAt: DateTime(2026, 6, 9),
      obtainedFrom: 'p0_e2e',
      school: school,
      baseAttack: (def.baseAttackMin + def.baseAttackMax) ~/ 2,
      baseHealth: (def.baseHealthMin + def.baseHealthMax) ~/ 2,
      baseSpeed: (def.baseSpeedMin + def.baseSpeedMax) ~/ 2,
      enhanceLevel: enhanceLevel,
      battleCount: battleCount,
    ));
  }

  // tier-cap 主修心法(production techniqueDefs · 真 skillIds)。
  final techTierCap = RealmUtils.techniqueTierCapOf(tier);
  final TechniqueDef techDef =
      repo.techniqueDefs.values.firstWhere((d) => d.tier == techTierCap);
  final mainTech = Technique.create(
    defId: techDef.id,
    ownerCharacterId: 999 + slot,
    tier: techDef.tier,
    school: school,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 6, 9),
    cultivationLayer: CultivationLayer.daCheng,
  );

  final attributes = Attributes()
    ..constitution = 6
    ..agility = 6
    ..enlightenment = 5
    ..fortune = 5;

  final character = Character.create(
    name: name,
    realmTier: tier,
    realmLayer: layer,
    attributes: attributes,
    rarity: RarityTier.values.first,
    lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
    createdAt: DateTime(2026, 6, 9),
    internalForce: realmDef.internalForceMax,
    internalForceMax: realmDef.internalForceMax,
    school: school,
    isFounder: isFounder,
    isActive: true,
  )..id = 999 + slot;

  return BattleCharacter.fromCharacter(
    character: character,
    equipped: equipped,
    mainTechnique: mainTech,
    numbers: numbers,
    teamSide: 0,
    slotIndex: slot,
    founderBuffActive: true, // ceiling:玩家在门派、祖师在世 → 享 founder buff
  );
}
