import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';

/// Task 2: seedVisualMasterAllTiers 单元测试。
///
/// 覆盖:
/// - 跑 seedVisualMasterAllTiers 后,characters 里有武圣角色且 mainTechniqueId 非空。
/// - techniques 里 7 个 tier 各至少 1 本(tier 集合长度 == TechniqueTier.values.length)。
/// - 所有心法 tier ≤ RealmUtils.techniqueTierCapOf(ch.realmTier)(三系锁死合规)。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_visual_master_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('seedVisualMasterAllTiers → 1 武圣角色 + mainTechniqueId 非空', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualMasterAllTiers();
    final isar = IsarSetup.instance;

    expect(await isar.characters.count(), 1);

    final ch = await isar.characters.get(1);
    expect(ch, isNotNull);
    expect(ch!.realmTier, RealmTier.wuSheng,
        reason: '角色境界必须是武圣(cover 全 7 阶解锁前提)');
    expect(ch.realmLayer, RealmLayer.dengFeng,
        reason: '武圣最高层 dengFeng');
    expect(ch.mainTechniqueId, isNotNull,
        reason: 'TechniquePanelScreen 显 cover 需要 mainTechniqueId');
  });

  test('seedVisualMasterAllTiers → techniques 覆盖全 7 tier', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualMasterAllTiers();
    final isar = IsarSetup.instance;

    final techs = await isar.techniques.where().findAll();
    expect(techs.length, TechniqueTier.values.length,
        reason: '7 阶各 1 本心法');

    final tierSet = techs.map((t) => t.tier).toSet();
    expect(tierSet.length, TechniqueTier.values.length,
        reason: '7 个 tier 每阶都有心法(不重复不遗漏)');

    for (final tier in TechniqueTier.values) {
      expect(tierSet.contains(tier), isTrue,
          reason: '${tier.name} 阶心法必须在 isar.techniques 中');
    }
  });

  test('seedVisualMasterAllTiers → 所有心法 tier ≤ 武圣上限(三系锁死合规)', () async {
    await Phase2SeedService(isar: IsarSetup.instance).seedVisualMasterAllTiers();
    final isar = IsarSetup.instance;

    final ch = await isar.characters.get(1);
    expect(ch, isNotNull);

    final cap = RealmUtils.techniqueTierCapOf(ch!.realmTier);
    expect(cap, TechniqueTier.chuanShuoShenGong,
        reason: '武圣上限必须是传说神功(全 7 阶合法)');

    final techs = await isar.techniques.where().findAll();
    for (final t in techs) {
      expect(t.tier.index <= cap.index, isTrue,
          reason: '${t.defId} tier=${t.tier.name} 超过上限 cap=${cap.name}');
    }
  });

  test('seedVisualMasterAllTiers 反复调用 → 仍 7 本(幂等)', () async {
    final isar = IsarSetup.instance;
    await Phase2SeedService(isar: isar).seedVisualMasterAllTiers();
    await Phase2SeedService(isar: isar).seedVisualMasterAllTiers();

    expect(await isar.techniques.count(), TechniqueTier.values.length,
        reason: '_clearAll 保证反复 reseed 不重复 append');
    expect(await isar.characters.count(), 1);
  });
}
