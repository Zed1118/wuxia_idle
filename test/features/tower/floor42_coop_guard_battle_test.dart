import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import '../../support/test_data.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart'
    show RealmUtils;

/// 第八阶段切片 4-5 · floor42 敌方协同(掩护重定向+护法合击)实例确定性回归。
///
/// **软门槛不变量**(2026-08-06 校准定稿,诊断
/// test/tools/floor42_coop_guard_diagnostic_test.dart 三画像×20 seed 实测:
/// onLevel 100% / onLevelBare 15% / underTier 0%):
///   - on-level 宗师·登峰满配队 → 全自动必胜:破护法墙 + 击杀 Boss。
///   - 同阶 0 强化队 → 存在会败的确定 seed,且败局中协同机制真触发
///     (掩护重定向 + 护法合击均出现——机制触发回归红线,防实例配置被
///     改成死配置后梯度测仍假绿)。
///   - 跨 1 阶(绝顶)0 强化队 → 确定 seed 会败(门槛真咬合)。
///
/// **实例机制链**(towers.yaml floor42):CD 型 chargeSkillId 使 Boss 开局即
/// 周期蓄大招 → 掩护窗口落在护法存活期(诊断第 1 轮实证:仅 chargeCounter
/// 相位蓄招时 taunt 逼玩家先清护法,Boss 蓄力时护法必已死,机制 0 触发)。
///
/// **谐波路径**:ProviderContainer + 永久 listener + notifier.advance 全程推进
/// (注入单一 seeded rng),与生产自动战斗同路径;非 strategy.tick 裸调。
/// seed 按本路径实测校准(与 diagnostic 的 tick 裸调 rng 流不同源,不可转抄)。
void main() {
  setUpAll(() async {
    await loadTestGameRepository();
  });

  BattleState runFloor42(
    RealmTier tier, {
    required RealmLayer layer,
    required bool geared,
    required int seed,
  }) {
    final repo = GameRepository.instance;
    final floor42 = repo.getTowerFloor(42);
    final players = [
      for (var slot = 0; slot < 3; slot++)
        _buildPlayer(
          repo,
          tier,
          layer: layer,
          slot: slot,
          isFounder: slot == 0,
          geared: geared,
        ),
    ];
    final enemies = StageBattleSetup.buildEnemyTeam(
      floor42.enemyTeam,
      isTower: true,
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(
      battleProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(players, enemies, seed: seed);

    var guard = 0;
    while (!container.read(battleProvider).isFinished && guard < 5000) {
      notifier.advance();
      guard++;
    }
    return container.read(battleProvider);
  }

  test('on-level 宗师·登峰满配队全自动必胜:破护法墙 + 击杀 Boss', () {
    final s = runFloor42(
      RealmTier.zongShi,
      layer: RealmLayer.dengFeng,
      geared: true,
      seed: 0,
    );

    expect(s.isFinished, isTrue, reason: '应在 guard 内分出胜负');
    expect(s.result, BattleResult.leftWin, reason: 'on-level 满配队应必胜');

    final guardiansAlive = s.rightTeam
        .where(
          (e) =>
              (e.enemyDefId == 'enemy_tower_42_guard_a' ||
                  e.enemyDefId == 'enemy_tower_42_guard_b') &&
              e.isAlive,
        )
        .length;
    expect(guardiansAlive, 0, reason: '必胜路径应清空双护法');

    final boss = s.rightTeam.firstWhere(
      (e) => e.enemyDefId == 'enemy_tower_boss_42',
    );
    expect(boss.isAlive, isFalse, reason: '破墙后应击杀主 Boss');

    expect(s.actionLog.length, greaterThan(3), reason: '应产生实际交战动作,非空过');
  });

  test('同阶 0 强化队确定 seed 会败,且掩护重定向+护法合击真触发(机制回归红线)', () {
    final s = runFloor42(
      RealmTier.zongShi,
      layer: RealmLayer.dengFeng,
      geared: false,
      seed: 0,
    );

    expect(s.isFinished, isTrue, reason: '应在 guard 内分出胜负');
    expect(
      s.result,
      BattleResult.rightWin,
      reason: '同阶 0 强化应在此 seed 败于协同压制(软门槛档,诊断 15% 偶胜)',
    );

    // 机制触发红线:协同机制在真实 floor42 配置下真发生,防「实例配置被改成
    // 死配置(如撤掉 CD 蓄招退回纯相位蓄招)后梯度断言仍假绿」。
    final intercepts = s.actionLog.where((a) => a.guardIntercepted).length;
    final coopStrikes = s.actionLog
        .where((a) => a.coopStrikeTotalDamage != null)
        .length;
    expect(
      intercepts,
      greaterThan(0),
      reason: '败局中掩护重定向应真触发(0=协同机制死配置)',
    );
    expect(
      coopStrikes,
      greaterThan(0),
      reason: '败局中护法合击应真触发(0=协同机制死配置)',
    );
  });

  test('跨 1 阶(绝顶)0 强化队确定 seed 会败(门槛真咬合)', () {
    final s = runFloor42(
      RealmTier.jueDing,
      layer: RealmLayer.dengFeng,
      geared: false,
      seed: 0,
    );

    expect(s.isFinished, isTrue, reason: '应在 guard 内分出胜负');
    expect(
      s.result,
      BattleResult.rightWin,
      reason: '跨阶欠配应被协同 Boss 拦住(诊断 0/20 全败)',
    );

    final playersAlive = s.leftTeam.where((p) => p.isAlive).length;
    expect(playersAlive, 0, reason: '败局应为玩家团灭');

    expect(s.actionLog.length, greaterThan(3), reason: '应产生实际交战动作,非空过');
  });
}

BattleCharacter _buildPlayer(
  GameRepository repo,
  RealmTier tier, {
  required RealmLayer layer,
  required int slot,
  required bool isFounder,
  required bool geared,
}) {
  const school = TechniqueSchool.gangMeng;
  final numbers = repo.numbers;
  final realmDef = repo.getRealm(tier, layer);
  final enhanceLevel = geared ? (realmDef.absoluteLevel * 0.5).round() : 0;
  final battleCount = geared ? 400 : 0;

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
        obtainedAt: DateTime(2026, 8, 6),
        obtainedFrom: 'floor42_coop_guard',
        school: school,
        baseAttack: (def.baseAttackMin + def.baseAttackMax) ~/ 2,
        baseHealth: (def.baseHealthMin + def.baseHealthMax) ~/ 2,
        baseSpeed: (def.baseSpeedMin + def.baseSpeedMax) ~/ 2,
        enhanceLevel: enhanceLevel,
        battleCount: battleCount,
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
    learnedAt: DateTime(2026, 8, 6),
    cultivationLayer: geared
        ? CultivationLayer.daCheng
        : CultivationLayer.zhongCheng,
  );

  final attributes = Attributes()
    ..constitution = geared ? 6 : 5
    ..agility = geared ? 6 : 5
    ..enlightenment = 5
    ..fortune = 5;

  final character = Character.create(
    name: '玩家$slot',
    realmTier: tier,
    realmLayer: layer,
    attributes: attributes,
    rarity: RarityTier.values.first,
    lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
    createdAt: DateTime(2026, 8, 6),
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
    founderBuffActive: geared,
  );
}
