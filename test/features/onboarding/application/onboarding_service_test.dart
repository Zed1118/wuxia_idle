import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/stage_battle_setup.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';

/// 2026-05-25 P0-1 release 阻塞修复 R5 测族(8 测)。
///
/// 验证 [OnboardingService.ensureFoundingMasters] production seed 路径:
/// - R5.1 全新 db → 返 true · Character × 3 · SaveData wire
/// - R5.2 二次调用幂等 → 返 false · Character count 不增
/// - R5.3 founder 存在但 SaveData 空 → 返 false(信源 Character ≠ SaveData)
/// - R5.4 装备 9 + 心法 4 spot-check
/// - R5.5 真战斗 e2e:StageBattleSetup._buildPlayerTeam 不抛 StateError
/// - R5.6 founder.id=1 锚定
/// - R5.7 SaveData.sectName ??= 不覆盖既有
/// - R5.8 基础物料 50/0 锚定
///
/// 沿 [Phase2SeedService] test 体例:tempDir + Isar.init + GameRepository.loadAllDefs。
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_onboarding_test_');
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

  test('R5.1 全新 db ensureFoundingMasters → true + Character × 3 + SaveData wire',
      () async {
    final isar = IsarSetup.instance;
    final svc = OnboardingService(isar: isar);

    final result = await svc.ensureFoundingMasters();

    expect(result, isTrue);
    expect(await isar.characters.count(), 3);

    final founder = await isar.characters.get(1);
    expect(founder, isNotNull);
    expect(founder!.isFounder, isTrue);
    expect(founder.lineageRole, LineageRole.founder);
    expect(founder.realmTier, RealmTier.yiLiu);
    expect(founder.discipleIds.length, 2);

    final save = await isar.saveDatas.get(0);
    expect(save, isNotNull);
    expect(save!.activeCharacterIds, [1, 2, 3]);
    expect(save.founderCharacterId, 1);
    expect(save.sectName, '我的门派');
  });

  test('R5.2 二次调用幂等 → false + Character count 不增', () async {
    final isar = IsarSetup.instance;
    final svc = OnboardingService(isar: isar);

    final first = await svc.ensureFoundingMasters();
    expect(first, isTrue);
    final firstCount = await isar.characters.count();

    final second = await svc.ensureFoundingMasters();
    expect(second, isFalse);
    expect(await isar.characters.count(), firstCount);
  });

  test('R5.3 founder 已存在但 SaveData 空 → false(信源 Character)', () async {
    final isar = IsarSetup.instance;

    // 手动写一个 founder(isFounder=true)模拟「Character 存在 / SaveData
    // activeCharacterIds 被清空」异常态。
    await isar.writeTxn(() async {
      final fakeFounder = Character.create(
        name: '残留祖师',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes()
          ..constitution = 5
          ..enlightenment = 5
          ..agility = 5
          ..fortune = 5,
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        isFounder: true,
        createdAt: DateTime.now(),
        internalForce: 1000,
        internalForceMax: 1000,
        isActive: true,
      );
      await isar.characters.put(fakeFounder);
    });

    final svc = OnboardingService(isar: isar);
    final result = await svc.ensureFoundingMasters();

    expect(result, isFalse);
    expect(await isar.characters.count(), 1); // 不重 seed
  });

  test('R5.4 装备 9 件 + 心法 4 本 spot-check', () async {
    final isar = IsarSetup.instance;
    await OnboardingService(isar: isar).ensureFoundingMasters();

    expect(await isar.equipments.count(), 9); // 3 角色 × 3 槽
    expect(await isar.techniques.count(), 4); // founder 2 + 大弟子 1 + 二弟子 1

    final founder = await isar.characters.get(1);
    expect(founder!.equippedWeaponId, isNotNull);
    expect(founder.equippedArmorId, isNotNull);
    expect(founder.equippedAccessoryId, isNotNull);
    expect(founder.mainTechniqueId, isNotNull);
    expect(founder.assistTechniqueIds.length, 1);
  });

  test('R5.5 真战斗 e2e:StageBattleSetup._buildPlayerTeam 不抛 StateError',
      () async {
    final isar = IsarSetup.instance;
    await OnboardingService(isar: isar).ensureFoundingMasters();

    // audit P0-1 复现 → 修:onboarding 后 buildTeams 应返 (左 3, 右 ≥1)。
    final stage = GameRepository.instance.getStage('stage_01_01');
    final setup = StageBattleSetup(isar: isar);
    final (left, right) = await setup.buildTeams(stage);

    expect(left.length, 3); // 3 师徒入阵
    expect(right.length, greaterThan(0));
    // 不抛 StateError = audit P0-1 修复成功
  });

  test('R5.6 founder.id 严格锚定 1', () async {
    final isar = IsarSetup.instance;
    await OnboardingService(isar: isar).ensureFoundingMasters();

    final founder = await isar.characters
        .filter()
        .isFounderEqualTo(true)
        .findFirst();
    expect(founder?.id, 1);
  });

  test('R5.7 sectName ??= 不覆盖既有(玩家 1.1 自定义后保留)', () async {
    final isar = IsarSetup.instance;

    // 先写 SaveData.sectName(模拟 1.1 用户自定义场景)。
    await isar.writeTxn(() async {
      final save = await isar.saveDatas.get(0);
      save!.sectName = '剑湖派';
      await isar.saveDatas.put(save);
    });

    await OnboardingService(isar: isar).ensureFoundingMasters();

    final save = await isar.saveDatas.get(0);
    expect(save!.sectName, '剑湖派'); // 不被覆盖
  });

  test('R5.8 基础物料 50/0 锚定(§5.1 反留存不爆量)', () async {
    final isar = IsarSetup.instance;
    await OnboardingService(isar: isar).ensureFoundingMasters();

    final moj = await isar.inventoryItems
        .filter()
        .itemTypeEqualTo(ItemType.moJianShi)
        .findFirst();
    final jie = await isar.inventoryItems
        .filter()
        .itemTypeEqualTo(ItemType.xinXueJieJing)
        .findFirst();
    expect(moj?.quantity, 50);
    expect(jie?.quantity, 0);
  });
}

