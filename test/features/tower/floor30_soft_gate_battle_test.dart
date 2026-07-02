import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
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
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart'
    show RealmUtils;

/// Task 5 · floor30 护法结界软门槛确定性回归。
///
/// **软门槛不变量**(spec §4.3):
///   - on-level 宗师满配队 → 全自动打 floor30 必胜(先清双护法破结界 → 秒 Boss),
///     不削弱极值爽感。
///   - under-geared(-1 阶绝顶,0 强化 0 战意)队 → 存在会输的确定 seed
///     (护法当血墙 + 攻击压力拖垮清关窗口)。
///
/// **诊断实测背景**(test/tools/floor30_soft_gate_diagnostic_test.dart,30 seed):
///   guardian HP 9000/8500, ward 0.15 时 → onLevel 100% 胜 / underGear 66.7% 胜
///   (33% 败)。护法 HP 提到 ≥9250 即崩到 13.3% 胜(离散悬崖),9000/8500 是
///   「仍算软门槛」的甜点。**注意**:全自动 lowest-HP 选敌下,Boss 在护法全灭
///   前从不被攻击,故 guardianWard.damageTakenMult 对自动战斗无实效——门槛全由
///   护法血墙+攻击压力构成。damageTakenMult 只对手动越过护法直捶 Boss 的玩家生效。
///
/// **谐波路径**:经 ProviderContainer + 永久 listener + notifier.advance 全程
/// 推进(注入单一 seeded rng),与生产自动战斗同路径;非 strategy.tick 裸调。
/// 队伍为真实满/欠配 BattleCharacter(真装备/心法/属性),非扁平 stub。
void main() {
  setUpAll(() async {
    // loadAllDefs 设 GameRepository.instance 单例;advance() 的
    // numbersConfigProvider 默认实现读该单例。
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  BattleState runFloor30(RealmTier tier, {required bool geared, required int seed}) {
    final repo = GameRepository.instance;
    final floor30 = repo.getTowerFloor(30);
    final players = [
      for (var slot = 0; slot < 3; slot++)
        _buildPlayer(repo, tier,
            slot: slot, isFounder: slot == 0, geared: geared),
    ];
    final enemies = StageBattleSetup.buildEnemyTeam(
      floor30.enemyTeam,
      isTower: true,
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    // 永久 listener 防 autoDispose 在 read 间隙释放 notifier。
    final sub =
        container.listen(battleProvider, (_, _) {}, fireImmediately: true);
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

  test('on-level 宗师满配队全自动必胜:破结界 + 击杀 Boss(极值爽感不削)', () {
    final s = runFloor30(RealmTier.zongShi, geared: true, seed: 0);

    expect(s.isFinished, isTrue, reason: '应在 guard 内分出胜负');
    expect(s.result, BattleResult.leftWin, reason: 'on-level 满配队应必胜');

    // 破结界:两护法皆亡。
    final guardiansAlive = s.rightTeam
        .where((e) =>
            (e.enemyDefId == 'enemy_tower_30_cultist_a' ||
                e.enemyDefId == 'enemy_tower_30_cultist_b') &&
            e.isAlive)
        .length;
    expect(guardiansAlive, 0, reason: '必胜路径应清空双护法破结界');

    // 击杀主 Boss。
    final boss = s.rightTeam
        .firstWhere((e) => e.enemyDefId == 'enemy_tower_boss_30');
    expect(boss.isAlive, isFalse, reason: '破结界后应击杀主 Boss');

    // 非空过:确有交战动作。
    expect(s.actionLog.length, greaterThan(3),
        reason: '应产生实际交战动作,非空过');
  });

  test('under-geared 绝顶(-1 阶)0 强化队在确定 seed 会败(护法软门槛咬合)', () {
    // seed 8:诊断中 underGear rightWin(tick~5,团灭于清关窗口)。
    final s = runFloor30(RealmTier.jueDing, geared: false, seed: 8);

    expect(s.isFinished, isTrue, reason: '应在 guard 内分出胜负');
    expect(s.result, BattleResult.rightWin,
        reason: 'under-geared 队应被护法血墙+攻击压力拖垮而败——软门槛咬合');

    // 玩家团灭(全败),非平局/超时。
    final playersAlive = s.leftTeam.where((p) => p.isAlive).length;
    expect(playersAlive, 0, reason: '败局应为玩家团灭');

    // 非空过:确有交战动作。
    expect(s.actionLog.length, greaterThan(3),
        reason: '应产生实际交战动作,非空过');
  });
}

BattleCharacter _buildPlayer(
  GameRepository repo,
  RealmTier tier, {
  required int slot,
  required bool isFounder,
  required bool geared,
}) {
  const layer = RealmLayer.huaJing;
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
        obtainedAt: DateTime(2026, 6, 28),
        obtainedFrom: 'floor30_soft_gate',
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
    learnedAt: DateTime(2026, 6, 28),
    cultivationLayer:
        geared ? CultivationLayer.daCheng : CultivationLayer.zhongCheng,
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
    createdAt: DateTime(2026, 6, 28),
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
