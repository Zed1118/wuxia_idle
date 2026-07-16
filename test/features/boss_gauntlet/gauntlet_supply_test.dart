import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/defs/item_def.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';

/// C2.2 整备页用药 + 关闭返还（守恒·spec §5.1/§9.2）。
/// 直接构造 interlude 会话 + 注入 itemDefs（轻量·不载 GameRepository）。
void main() {
  late Directory tempDir;

  final itemDefs = <String, ItemDef>{
    'item_liaoshangdan': const ItemDef(
      defId: 'item_liaoshangdan',
      type: ItemType.miscMaterial,
      name: '疗伤丹',
      gauntletHpHealPct: 0.30,
    ),
    'item_xingnang_buji': const ItemDef(
      defId: 'item_xingnang_buji',
      type: ItemType.miscMaterial,
      name: '行囊补给',
      gauntletQiRestorePct: 0.20,
    ),
  };

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_supply_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.37.0'
          ..createdAt = DateTime(2026, 7, 17)
          ..lastSavedAt = DateTime(2026, 7, 17)
          ..lastOnlineAt = DateTime(2026, 7, 17),
      );
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ActivityMemberSnapshot member(
    int id, {
    required int maxHp,
    required int currentHp,
    int maxQi = 100,
    int currentQi = 0,
    bool downed = false,
  }) =>
      ActivityMemberSnapshot()
        ..characterId = id
        ..maxHp = maxHp
        ..currentHp = currentHp
        ..maxQi = maxQi
        ..currentQi = currentQi
        ..isDowned = downed;

  Future<int> putRun({
    GauntletPhase phase = GauntletPhase.interlude,
    required List<ActivityMemberSnapshot> members,
    List<String> escrowDefIds = const [],
    List<int> escrowLoaded = const [],
    List<int> escrowUsed = const [],
  }) async {
    late int id;
    await IsarSetup.instance.writeTxn(() async {
      id = await IsarSetup.instance.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 0
          ..currentStage = 2
          ..sessionPhase = phase
          ..members = members
          ..escrowItemDefIds = List.of(escrowDefIds)
          ..escrowLoadedQty = List.of(escrowLoaded)
          ..escrowUsedQty = List.of(escrowUsed),
      );
    });
    return id;
  }

  Future<void> putInventory(String defId, int qty) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.inventoryItems.put(
        InventoryItem()
          ..defId = defId
          ..itemType = ItemType.miscMaterial
          ..quantity = qty
          ..firstObtainedAt = DateTime(2026, 7, 17)
          ..lastObtainedAt = DateTime(2026, 7, 17),
      );
    });
  }

  Future<int?> qtyOf(String defId) async =>
      (await IsarSetup.instance.inventoryItems.getByDefId(defId))?.quantity;

  Future<BossGauntletRun> reloadRun() async =>
      (await IsarSetup.instance.bossGauntletRuns.where().findAll()).single;

  GauntletService svc() => GauntletService(IsarSetup.instance, itemDefs: itemDefs);

  test('疗伤丹恢复目标 30% maxHp（只减托管 UsedQty·不碰普通库存）', () async {
    await putRun(
      members: [member(1, maxHp: 1000, currentHp: 400)],
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [2],
      escrowUsed: [0],
    );
    await putInventory('item_liaoshangdan', 5); // 普通库存余量·不应变

    await svc().useSupply(index: 0, targetCharacterId: 1);

    final run = await reloadRun();
    expect(run.members.single.currentHp, 700); // 400 + 0.30×1000
    expect(run.escrowUsedQty, [1]);
    expect(run.escrowLoadedQty, [2]); // 装入量不变
    expect(await qtyOf('item_liaoshangdan'), 5); // 不碰普通库存
  });

  test('疗伤丹恢复钳到 maxHp（不溢出）', () async {
    await putRun(
      members: [member(1, maxHp: 1000, currentHp: 900)],
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [1],
      escrowUsed: [0],
    );
    await svc().useSupply(index: 0, targetCharacterId: 1);
    expect((await reloadRun()).members.single.currentHp, 1000); // 900+300 钳 1000
  });

  test('行囊补给恢复全体存活 20% maxQi（跳过倒下者·钳 maxQi）', () async {
    await putRun(
      members: [
        member(1, maxHp: 1000, currentHp: 500, maxQi: 140, currentQi: 40),
        member(2, maxHp: 1000, currentHp: 0, maxQi: 100, currentQi: 10, downed: true),
        member(3, maxHp: 1000, currentHp: 800, maxQi: 140, currentQi: 140),
      ],
      escrowDefIds: ['item_xingnang_buji'],
      escrowLoaded: [1],
      escrowUsed: [0],
    );
    await svc().useSupply(index: 0); // 全体·无 target

    final run = await reloadRun();
    expect(run.members[0].currentQi, 68); // 40 + 0.20×140=28
    expect(run.members[1].currentQi, 10); // 倒下者不恢复
    expect(run.members[2].currentQi, 140); // 140+28 钳 140
    expect(run.escrowUsedQty, [1]);
  });

  test('补给用尽（Used==Loaded）→ 抛错', () async {
    await putRun(
      members: [member(1, maxHp: 1000, currentHp: 400)],
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [1],
      escrowUsed: [1],
    );
    await expectLater(
        svc().useSupply(index: 0, targetCharacterId: 1), throwsStateError);
  });

  test('非整备页（inBattle）用药 → 抛错', () async {
    await putRun(
      phase: GauntletPhase.inBattle,
      members: [member(1, maxHp: 1000, currentHp: 400)],
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [1],
      escrowUsed: [0],
    );
    await expectLater(
        svc().useSupply(index: 0, targetCharacterId: 1), throwsStateError);
  });

  test('疗伤丹对倒下者用药 → 抛错', () async {
    await putRun(
      members: [member(1, maxHp: 1000, currentHp: 0, downed: true)],
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [1],
      escrowUsed: [0],
    );
    await expectLater(
        svc().useSupply(index: 0, targetCharacterId: 1), throwsStateError);
  });

  test('疗伤丹无目标 → 抛错', () async {
    await putRun(
      members: [member(1, maxHp: 1000, currentHp: 400)],
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [1],
      escrowUsed: [0],
    );
    await expectLater(svc().useSupply(index: 0), throwsStateError);
  });

  test('index 越界 → 抛错', () async {
    await putRun(
      members: [member(1, maxHp: 1000, currentHp: 400)],
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [1],
      escrowUsed: [0],
    );
    await expectLater(
        svc().useSupply(index: 3, targetCharacterId: 1), throwsStateError);
  });

  test('close 返还 Loaded-Used 到普通库存 + 删 run', () async {
    await putRun(
      members: [member(1, maxHp: 1000, currentHp: 100)],
      escrowDefIds: ['item_liaoshangdan', 'item_xingnang_buji'],
      escrowLoaded: [2, 1],
      escrowUsed: [1, 0],
    );
    await putInventory('item_liaoshangdan', 0);
    await putInventory('item_xingnang_buji', 0);

    await svc().close();

    expect(await qtyOf('item_liaoshangdan'), 1); // 2-1
    expect(await qtyOf('item_xingnang_buji'), 1); // 1-0
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });

  test('close 全用完 → 无返还·删 run', () async {
    await putRun(
      members: [member(1, maxHp: 1000, currentHp: 100)],
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [2],
      escrowUsed: [2],
    );
    await putInventory('item_liaoshangdan', 0);
    await svc().close();
    expect(await qtyOf('item_liaoshangdan'), 0);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });

  test('close 无 active 会话 → 幂等 no-op（不抛）', () async {
    await svc().close();
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });

  test('守恒：装入 = 已用 + 返还（useSupply×2 → close）', () async {
    await putRun(
      members: [member(1, maxHp: 1000, currentHp: 100)],
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [3],
      escrowUsed: [0],
    );
    await putInventory('item_liaoshangdan', 0); // 已全移入托管
    final s = svc();
    await s.useSupply(index: 0, targetCharacterId: 1);
    await s.useSupply(index: 0, targetCharacterId: 1); // used → 2
    await s.close();
    // 装入 3 = 已用 2 + 返还 1
    expect(await qtyOf('item_liaoshangdan'), 1);
    expect(await IsarSetup.instance.bossGauntletRuns.count(), 0);
  });

  test('close 库存行缺失 → 据 itemDef 重建返还（防御）', () async {
    await putRun(
      members: [member(1, maxHp: 1000, currentHp: 100)],
      escrowDefIds: ['item_liaoshangdan'],
      escrowLoaded: [2],
      escrowUsed: [0],
    );
    // 无 item_liaoshangdan 库存行
    await svc().close();
    final item = await IsarSetup.instance.inventoryItems
        .getByDefId('item_liaoshangdan');
    expect(item, isNotNull);
    expect(item!.quantity, 2);
    expect(item.itemType, ItemType.miscMaterial);
  });
}
