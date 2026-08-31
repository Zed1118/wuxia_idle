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
import 'package:wuxia_idle/features/boss_gauntlet/domain/gauntlet_automation_policy.dart';

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
          ..saveVersion = '0.38.0'
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
    bool isAlive = true,
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
        ..isAlive = isAlive
        ..equippedWeaponId = weaponId
        ..mainTechniqueId = mainTech
        ..assistTechniqueIds = assist
        ..currentRetreatSessionId = retreatSessionId;
      id = await IsarSetup.instance.characters.put(c);
    });
    return id;
  }

  Future<void> setCurrentLeader(int characterId) async {
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.founderCharacterId = characterId;
      await IsarSetup.instance.saveDatas.put(save);
    });
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
    // 新会话 seed 按不可变 slotId 稳定派生；每关再混 currentStage。
    expect(run.seed, 1);

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

  test('自动首通门槛在扣帖与建会话前 fail closed', () async {
    final cid = await putDisciple(mainTech: 5);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    final svc = GauntletService(IsarSetup.instance);

    await expectLater(
      svc.enter(
        characterIds: [cid],
        supplyCap: 3,
        automationRequest: gauntletHeadlessReplayRequest(characterId: cid),
      ),
      throwsStateError,
    );

    expect(await qtyOf('item_duanhuntie'), 1);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });

  test('新会话 seed 同 slot 稳定、不同 slot 不同', () async {
    final cid = await putDisciple(mainTech: 5);
    await putInventory('item_duanhuntie', ItemType.ticket, 3);
    final svc = GauntletService(IsarSetup.instance);

    Future<int> enterForSlot(int slotId) async {
      await IsarSetup.instance.writeTxn(() async {
        final save = (await IsarSetup.instance.saveDatas.get(0))!;
        save.slotId = slotId;
        await IsarSetup.instance.saveDatas.put(save);
        await IsarSetup.instance.bossGauntletRuns.clear();
      });
      final runId = await svc.enter(characterIds: [cid], supplyCap: 3);
      return (await IsarSetup.instance.bossGauntletRuns.get(runId))!.seed;
    }

    final slot1First = await enterForSlot(1);
    final slot1Again = await enterForSlot(1);
    final slot2 = await enterForSlot(2);

    expect(slot1Again, slot1First);
    expect(slot2, isNot(slot1First));
  });

  test('队伍为空 → 抛错', () async {
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(characterIds: [], supplyCap: 3),
      throwsStateError,
    );
  });

  test('路线 C 多于 1 人 → 抛错且不扣帖、不建新会话', () async {
    final ids = [for (var i = 0; i < 2; i++) await putDisciple(mainTech: 5)];
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(characterIds: ids, supplyCap: 3),
      throwsStateError,
    );
    expect(await qtyOf('item_duanhuntie'), 1);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
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

  test('空闲当前掌门可入庄，真实会话成员指向掌门', () async {
    final founder = await putDisciple(isFounder: true, mainTech: 5);
    await setCurrentLeader(founder);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    final runId = await GauntletService(
      IsarSetup.instance,
    ).enter(characterIds: [founder], supplyCap: 3);

    final run = await IsarSetup.instance.bossGauntletRuns.get(runId);
    expect(run, isNotNull);
    expect(run!.members.single.characterId, founder);
  });

  test('非当前的历史祖师不可入庄且不扣帖', () async {
    final current = await putDisciple(isFounder: true, mainTech: 5);
    final historical = await putDisciple(isFounder: true, mainTech: 6);
    await setCurrentLeader(current);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);

    await expectLater(
      GauntletService(
        IsarSetup.instance,
      ).enter(characterIds: [historical], supplyCap: 3),
      throwsStateError,
    );
    expect(await qtyOf('item_duanhuntie'), 1);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });

  test('闭关中的当前掌门不可入庄且不扣帖', () async {
    final cid = await putDisciple(
      isFounder: true,
      mainTech: 5,
      retreatSessionId: 9,
    );
    await setCurrentLeader(cid);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(characterIds: [cid], supplyCap: 3),
      throwsStateError,
    );
    expect(await qtyOf('item_duanhuntie'), 1);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });

  test('已故当前掌门不可入庄且不扣帖', () async {
    final cid = await putDisciple(isFounder: true, isAlive: false, mainTech: 5);
    await setCurrentLeader(cid);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);

    await expectLater(
      GauntletService(
        IsarSetup.instance,
      ).enter(characterIds: [cid], supplyCap: 3),
      throwsStateError,
    );
    expect(await qtyOf('item_duanhuntie'), 1);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
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

  test('补给份数非正（0）→ 抛错（前置校验·不进事务）', () async {
    final cid = await putDisciple(mainTech: 5);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    await putInventory('item_liaoshangdan', ItemType.miscMaterial, 2);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(
        characterIds: [cid],
        supplies: {'item_liaoshangdan': 0},
        supplyCap: 3,
      ),
      throwsStateError,
    );
    expect(await qtyOf('item_duanhuntie'), 1);
    expect(await qtyOf('item_liaoshangdan'), 2);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });

  test('无存档 → 抛错（事务回滚·无 run）', () async {
    final cid = await putDisciple(mainTech: 5);
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.delete(0);
    });
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(characterIds: [cid], supplyCap: 3),
      throwsStateError,
    );
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
    expect(await qtyOf('item_duanhuntie'), 1, reason: '帖未扣');
  });

  test('角色不存在 → 抛错且回滚（帖未扣）', () async {
    await putInventory('item_duanhuntie', ItemType.ticket, 1);
    final svc = GauntletService(IsarSetup.instance);
    await expectLater(
      svc.enter(characterIds: [999], supplyCap: 3),
      throwsStateError,
    );
    expect(await qtyOf('item_duanhuntie'), 1);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });
}
