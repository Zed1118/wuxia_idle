import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';

import '../../support/isar_test_support.dart';

/// C2.1 入场扣帖 + 补给会话托管（单 `writeTxn`·spec §5.1/§9.2）。
/// 模板镜像 `expedition_dispatch_test.dart`；Isar-only 轻量环境（不载 GameRepository）。
void main() {
  late Directory tempDir;

  setUpAll(() => initializeTestIsarCore());

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_enter_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.37.0'
          ..createdAt = DateTime(2026, 7, 16)
          ..lastSavedAt = DateTime(2026, 7, 16)
          ..lastOnlineAt = DateTime(2026, 7, 16),
      );
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<int> putDisciple({
    bool isFounder = false,
    int? weaponId,
    int? mainTech,
    List<int> assist = const [],
    int? retreatSessionId,
  }) async {
    late int id;
    await IsarSetup.instance.writeTxn(() async {
      final c = Character()
        ..name = isFounder ? '祖师' : '弟子'
        ..realmTier = RealmTier.sanLiu
        ..realmLayer = RealmLayer.qiMeng
        ..attributes = Attributes()
        ..rarity = RarityTier.biaoZhun
        ..lineageRole = isFounder ? LineageRole.founder : LineageRole.disciple
        ..createdAt = DateTime(2026, 7, 16)
        ..isFounder = isFounder
        ..equippedWeaponId = weaponId
        ..mainTechniqueId = mainTech
        ..assistTechniqueIds = assist
        ..currentRetreatSessionId = retreatSessionId;
      id = await IsarSetup.instance.characters.put(c);
    });
    return id;
  }

  Future<void> putInventory(String defId, ItemType type, int qty) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.inventoryItems.put(
        InventoryItem()
          ..defId = defId
          ..itemType = type
          ..quantity = qty
          ..firstObtainedAt = DateTime(2026, 7, 16)
          ..lastObtainedAt = DateTime(2026, 7, 16),
      );
    });
  }

  Future<int?> qtyOf(String defId) async =>
      (await IsarSetup.instance.inventoryItems.getByDefId(defId))?.quantity;

  test('成功入场：BossGauntletRun 落库 + 成员保留 id 快照 + escrow 托管 + '
      '扣一张断魂帖 + 普通库存守恒', () async {
    final cid = await putDisciple(weaponId: 100, mainTech: 5, assist: [6]);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    await putInventory('item_liaoshangdan', ItemType.miscMaterial, 3);
    await putInventory('item_xingnang_buji', ItemType.miscMaterial, 1);
    final svc = GauntletService(IsarSetup.instance);

    final runId = await svc.enter(
      characterIds: [cid],
      supplies: {'item_liaoshangdan': 2, 'item_xingnang_buji': 1},
      supplyCap: 3,
    );

    final run = await IsarSetup.instance.bossGauntletRuns.get(runId);
    expect(run, isNotNull);
    expect(run!.saveDataId, 0);
    expect(run.currentStage, 1);
    expect(run.sessionPhase, GauntletPhase.inBattle);
    // seed = saveId 派生（save.id=0）；每关混 currentStage 归 combat 层（后续切片）。
    expect(run.seed, 0);

    final member = run.members.single;
    expect(member.characterId, cid);
    expect(member.reservedEquipmentIds, [100]);
    expect(member.reservedTechniqueIds, [5, 6]);
    expect(member.currentHp, 0);
    expect(member.currentQi, 0);
    expect(member.isDowned, false);

    // 补给移入托管栏（平行三列表·插入序·usedQty 全 0）
    expect(run.escrowItemDefIds, ['item_liaoshangdan', 'item_xingnang_buji']);
    expect(run.escrowLoadedQty, [2, 1]);
    expect(run.escrowUsedQty, [0, 0]);

    // 扣一张断魂帖（消耗凭证与建会话同事务·§5.1）
    expect(await qtyOf('item_duanhuntie'), 0);

    // 普通库存守恒：扣量 == 托管装入量
    expect(await qtyOf('item_liaoshangdan'), 1); // 3 - 2
    expect(await qtyOf('item_xingnang_buji'), 0); // 1 - 1
  });

  test('队伍为空 → 抛错', () async {
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(characterIds: [], supplyCap: 3),
      throwsStateError,
    );
  });

  test('队伍超 3 人 → 抛错', () async {
    final ids = [for (var i = 0; i < 4; i++) await putDisciple(mainTech: 5)];
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(characterIds: ids, supplyCap: 3),
      throwsStateError,
    );
  });

  test('队伍含重复角色 → 抛错', () async {
    final cid = await putDisciple(mainTech: 5);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(characterIds: [cid, cid], supplyCap: 3),
      throwsStateError,
    );
  });

  test('祖师入队 → 抛错', () async {
    final founder = await putDisciple(isFounder: true, mainTech: 5);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(characterIds: [founder], supplyCap: 3),
      throwsStateError,
    );
  });

  test('已被占用角色（闭关中）→ 抛错', () async {
    final cid = await putDisciple(mainTech: 5, retreatSessionId: 9);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(characterIds: [cid], supplyCap: 3),
      throwsStateError,
    );
  });

  test('未修主修 → 抛错', () async {
    final cid = await putDisciple(mainTech: null);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(characterIds: [cid], supplyCap: 3),
      throwsStateError,
    );
  });

  test('每存档最多一条 active：二次入场 → 抛错', () async {
    final a = await putDisciple(mainTech: 5);
    final b = await putDisciple(mainTech: 7);
    await putInventory('item_duanhuntie', ItemType.ticket, 2);
    final svc = GauntletService(IsarSetup.instance);
    await svc.enter(characterIds: [a], supplyCap: 3);
    await expectLater(
      svc.enter(characterIds: [b], supplyCap: 3),
      throwsStateError,
    );
  });

  test('无断魂帖 → 抛错且事务回滚（补给不扣·无 run）', () async {
    final cid = await putDisciple(mainTech: 5);
    await putInventory('item_liaoshangdan', ItemType.miscMaterial, 2);
    // 未持有 item_duanhuntie
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(
        characterIds: [cid],
        supplies: {'item_liaoshangdan': 1},
        supplyCap: 3,
      ),
      throwsStateError,
    );
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
    expect(await qtyOf('item_liaoshangdan'), 2);
  });

  test('断魂帖数量为 0 → 抛错回滚', () async {
    final cid = await putDisciple(mainTech: 5);
    await putInventory('item_duanhuntie', ItemType.ticket, 0);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(characterIds: [cid], supplyCap: 3),
      throwsStateError,
    );
    expect(await qtyOf('item_duanhuntie'), 0);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });

  test('补给超上限（总份数 > supplyCap）→ 抛错', () async {
    final cid = await putDisciple(mainTech: 5);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    await putInventory('item_liaoshangdan', ItemType.miscMaterial, 5);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(
        characterIds: [cid],
        supplies: {'item_liaoshangdan': 4},
        supplyCap: 3,
      ),
      throwsStateError,
    );
  });

  test('补给库存不足 → 抛错且回滚（断魂帖未扣）', () async {
    final cid = await putDisciple(mainTech: 5);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    await putInventory('item_liaoshangdan', ItemType.miscMaterial, 1);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(
        characterIds: [cid],
        supplies: {'item_liaoshangdan': 2},
        supplyCap: 3,
      ),
      throwsStateError,
    );
    expect(await qtyOf('item_duanhuntie'), 1); // 事务回滚，帖未扣
    expect(await qtyOf('item_liaoshangdan'), 1);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });
}
