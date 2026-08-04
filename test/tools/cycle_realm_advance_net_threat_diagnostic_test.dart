// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart'
    show RealmUtils;
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';
import '../support/test_data.dart';

/// 批 B 净威胁实测（spec §1.3 挂账销账 · 2026-08-04）。
///
/// spec §1.3 解析推算：敌从 diff_3_or_more（近免疫，低打高 0.05）抬到
/// diff_2（0.3）时，敌输出 ×6 同时玩家输出 ×2.5，**净威胁增益约 2.4×**——
/// 批 A 时无境界推进路径无法实测，本批 B2 上线后在此销账。
///
/// 量法（第一版整场承伤口径被自证零负载否决——满配武圣 2.3 tick 秒杀轻功 05，
/// c1=c2=0，ratio=∞ 是假绿，守 memory feedback_probe_must_prove_its_load）：
/// 改 **calculator 层单发伤害交换比**，正对应 §1.3 的解析口径且无先手/秒杀噪声：
///   netThreat = (敌打玩家单发比 c2/c1) ÷ (玩家打敌单发比 c2/c1)。
/// 双向单发均关闪避/暴击（评期望基线）。战斗层另留两条真负载断言
/// （cycle3 承伤>0 且必胜），证机制在整场自动战斗里也真实咬合。
const String _stageId = 'stage_light_foot_05';

void main() {
  late GameRepository repo;
  late StageDef stage;

  setUpAll(() async {
    repo = await loadTestGameRepository();
    stage = repo.getStage(_stageId);
  });

  /// 敌 → 玩家 / 玩家 → 敌 的单发期望伤害（无闪避无暴击）。
  ({int enemyHitsPlayer, int playerHitsEnemy}) exchange(int cycleIndex) {
    final player = _buildPlayer(repo, RealmTier.wuSheng, slot: 0, isFounder: true);
    final enemy = StageBattleSetup.buildEnemyTeam(
      stage.enemyTeam,
      cycleIndex: cycleIndex,
      advanceRealmPerCycle: true,
    ).first;
    final n = repo.numbers;
    final noCritRng = Random(1);
    final enemySkill = enemy.availableSkills.first;
    final playerSkill = player.availableSkills.first;
    final e2p = DamageCalculator.calculateResolved(
      attackerInternalForce: enemy.internalForce,
      attackerEquipmentAttack: enemy.totalEquipmentAttack,
      attackerCultivationLayer: enemy.mainCultivationLayer,
      attackerSchool: enemy.school,
      defenderSchool: player.school,
      attackerRealmTier: enemy.realmTier,
      attackerRealmLayer: enemy.realmLayer,
      defenderRealmTier: player.realmTier,
      defenderRealmLayer: player.realmLayer,
      defenderDefenseRate: player.defenseRate,
      defenderEvasionRate: 0,
      attackerCriticalRate: 0,
      attackPowerMultiplier: 1.0,
      skill: enemySkill,
      n: n,
      rng: noCritRng,
    );
    final p2e = DamageCalculator.calculateResolved(
      attackerInternalForce: player.internalForce,
      attackerEquipmentAttack: player.totalEquipmentAttack,
      attackerCultivationLayer: player.mainCultivationLayer,
      attackerSchool: player.school,
      defenderSchool: enemy.school,
      attackerRealmTier: player.realmTier,
      attackerRealmLayer: player.realmLayer,
      defenderRealmTier: enemy.realmTier,
      defenderRealmLayer: enemy.realmLayer,
      defenderDefenseRate: enemy.defenseRate,
      defenderEvasionRate: 0,
      attackerCriticalRate: 0,
      attackPowerMultiplier: 1.0,
      skill: playerSkill,
      n: n,
      rng: noCritRng,
    );
    return (enemyHitsPlayer: e2p.finalDamage, playerHitsEnemy: p2e.finalDamage);
  }

  test('净威胁实测（calculator 单发交换比）：cycle2 解除近免疫', () {
    final c1 = exchange(1);
    final c2 = exchange(2);
    // 探针自证负载：四个单发值全部非零（否则量的是空气）。
    expect(c1.enemyHitsPlayer, greaterThan(0));
    expect(c1.playerHitsEnemy, greaterThan(0));
    expect(c2.enemyHitsPlayer, greaterThan(0));
    expect(c2.playerHitsEnemy, greaterThan(0));

    final enemyGain = c2.enemyHitsPlayer / c1.enemyHitsPlayer;
    final playerGain = c2.playerHitsEnemy / c1.playerHitsEnemy;
    final netThreat = enemyGain / playerGain;
    print(
      '[net-threat] e→p c1=${c1.enemyHitsPlayer} c2=${c2.enemyHitsPlayer} '
      '(×${enemyGain.toStringAsFixed(2)}) | p→e c1=${c1.playerHitsEnemy} '
      'c2=${c2.playerHitsEnemy} (×${playerGain.toStringAsFixed(2)}) | '
      'net=×${netThreat.toStringAsFixed(2)} (spec §1.3 解析 ~2.4)',
    );

    // spec §1.3 方向断言：净威胁显著 >1（近免疫解除后敌方净受益）。
    // 不钉 2.4：解析值只含差距表双向比（6/2.5），实测另含敌内力随境界表上涨
    // （攻方输出项）与玩家防御率固定等联动，数值必然偏离，方向为硬断言。
    expect(
      netThreat,
      greaterThan(1.5),
      reason: 'cycle2 境界推进（diff 5→2）应带来显著净威胁增益（spec §1.3）',
    );
    expect(
      enemyGain,
      greaterThan(3.0),
      reason: '敌打玩家单发应显著上升（0.05→0.3 输出乘子 ×6 + 内力上涨）',
    );
  });

  test('战斗层真负载：cycle3（clamp 武圣 diff0）整场承伤 >0 且满配必胜', () {
    var dmgTaken = 0;
    var wins = 0;
    const seeds = 20;
    for (var seed = 0; seed < seeds; seed++) {
      final r = _sim(repo, stage, cycleIndex: 3, seed: seed);
      dmgTaken += r.playerDamageTaken;
      if (r.result == 'leftWin') wins++;
    }
    print('[net-threat] battle c3 dmgTaken=$dmgTaken wins=$wins/$seeds');
    // 真负载自证：diff0 下敌能在整场自动战斗里造成非零伤害。
    expect(dmgTaken, greaterThan(0), reason: 'cycle3 敌应能真实造成承伤（机制咬合）');
    // 推进是威胁恢复非硬墙：武圣满配打 sanLiu 段支线 cycle3 仍必胜。
    expect(wins, equals(seeds), reason: '武圣满配打推进后的轻功 05 应必胜');
  }, timeout: const Timeout(Duration(minutes: 5)));
}

({String result, int playerDamageTaken}) _sim(
  GameRepository repo,
  StageDef stage, {
  required int cycleIndex,
  required int seed,
}) {
  final players = [
    for (var slot = 0; slot < 3; slot++)
      _buildPlayer(repo, RealmTier.wuSheng, slot: slot, isFounder: slot == 0),
  ];
  final enemies = StageBattleSetup.buildEnemyTeam(
    stage.enemyTeam,
    cycleIndex: cycleIndex,
    advanceRealmPerCycle: true,
  );
  final initial = BattleState.initial(leftTeam: players, rightTeam: enemies);
  final terminal = defaultGroundStrategy.runToEnd(
    initial,
    repo.numbers,
    maxTicks: 300,
    rng: Random(seed),
  );
  var taken = 0;
  for (final p in terminal.leftTeam) {
    taken += p.maxHp - p.currentHp;
  }
  return (
    result: terminal.result?.name ?? 'timeout',
    playerDamageTaken: taken,
  );
}

/// 满配武圣（同 vulnerability_window_diagnostic._buildPlayer geared 档：
/// 本阶满配 + 50% 强化 + 400 战意 + 创始 buff）。
BattleCharacter _buildPlayer(
  GameRepository repo,
  RealmTier tier, {
  required int slot,
  required bool isFounder,
}) {
  const school = TechniqueSchool.gangMeng;
  const layer = RealmLayer.dengFeng;
  final numbers = repo.numbers;
  final realmDef = repo.getRealm(tier, layer);
  final enhanceLevel = (realmDef.absoluteLevel * 0.5).round();

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
    equipped.add(
      Equipment.create(
        defId: def.id,
        tier: def.tier,
        slot: def.slot,
        obtainedAt: DateTime(2026, 8, 4),
        obtainedFrom: 'net_threat_diag',
        school: school,
        baseAttack: (def.baseAttackMin + def.baseAttackMax) ~/ 2,
        baseHealth: (def.baseHealthMin + def.baseHealthMax) ~/ 2,
        baseSpeed: (def.baseSpeedMin + def.baseSpeedMax) ~/ 2,
        enhanceLevel: enhanceLevel,
        battleCount: 400,
        forgingSlots: const [],
      ),
    );
  }

  final techTierCap = RealmUtils.techniqueTierCapOf(tier);
  final defsT = repo.techniqueDefs.values;
  final TechniqueDef techDef = defsT.firstWhere((d) => d.tier == techTierCap);
  final mainTech = Technique.create(
    defId: techDef.id,
    ownerCharacterId: 999 + slot,
    tier: techDef.tier,
    school: school,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 8, 4),
    cultivationLayer: CultivationLayer.daCheng,
  );

  final attributes = Attributes()
    ..constitution = 6
    ..agility = 6
    ..enlightenment = 5
    ..fortune = 5;

  final character = Character.create(
    name: '玩家$slot',
    realmTier: tier,
    realmLayer: layer,
    attributes: attributes,
    rarity: RarityTier.values.first,
    lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
    createdAt: DateTime(2026, 8, 4),
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
    founderBuffActive: true,
  );
}
