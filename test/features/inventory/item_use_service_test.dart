import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';
import 'package:wuxia_idle/data/defs/item_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/inventory/application/item_use_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Isar isar;
  late GameRepository repo;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    repo = await GameRepository.loadAllDefs();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_itemuse_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    isar = IsarSetup.instance;
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  // 预置 founder 角色（低境界，留升层空间）。Character.create 7 required 命名参。
  Future<int> seedFounder() async {
    late int id;
    await isar.writeTxn(() async {
      final c = Character.create(
        name: '主角',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.values.first,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026, 1, 1),
        isFounder: true,
        experience: 0,
        experienceToNextLayer: 100,
        internalForceMax: 800,
      );
      id = await isar.characters.put(c);
    });
    return id;
  }

  Future<void> seedItem(String defId, ItemType type, int qty) async {
    await isar.writeTxn(() async {
      await isar.inventoryItems.put(InventoryItem()
        ..defId = defId
        ..itemType = type
        ..quantity = qty
        ..firstObtainedAt = DateTime(2026, 1, 1)
        ..lastObtainedAt = DateTime(2026, 1, 1));
    });
  }

  test('经验丹：大还丹(fraction=1.0) 升满一层 + 消费 1', () async {
    // founder.experienceToNextLayer = 100；gain = round(100 × 1.0) = 100 → 恰好升1层。
    await seedFounder();
    await seedItem('item_jingyandan_large', ItemType.jingYanDan, 2);
    final def = repo.itemDefs['item_jingyandan_large']!; // layerFraction = 1.0

    final r = await ItemUseService.use(isar, def: def, realmLookup: repo.getRealm);

    expect(r.kind, ItemUseKind.experienceApplied);
    expect(r.layersGained, 1); // 100 经验恰好升 1 层
    final item = await isar.inventoryItems.getByDefId('item_jingyandan_large');
    expect(item?.quantity, 1); // 消费 1
  });

  test('经验丹：isLayerLocked 拦截 → 入账不升层（缩放后实际入账值）', () async {
    // founder.experienceToNextLayer = 100；大还丹 fraction=1.0；gain = round(100×1.0) = 100。
    await seedFounder();
    await seedItem('item_jingyandan_large', ItemType.jingYanDan, 1);
    final def = repo.itemDefs['item_jingyandan_large']!;

    final r = await ItemUseService.use(
      isar,
      def: def,
      realmLookup: repo.getRealm,
      isLayerLocked: (_, _) => true, // 全锁
    );

    expect(r.kind, ItemUseKind.experienceApplied);
    expect(r.layersGained, 0); // 锁住不升层
    final founder =
        await isar.characters.filter().isFounderEqualTo(true).findFirst();
    // 缩放入账：round(100 × 1.0) = 100（而非旧固定值 1800）。
    expect(founder?.experience, 100);
  });

  test('经验丹缩放：培元丹(fraction=0.5) 入账 = round(nextLayer × 0.5)', () async {
    // 验证缩放生效：gain = round(100 × 0.5) = 50，低于100所需不升层。
    await seedFounder(); // experienceToNextLayer = 100
    await seedItem('item_jingyandan_mid', ItemType.jingYanDan, 1);
    final def = repo.itemDefs['item_jingyandan_mid']!; // layerFraction = 0.5

    final r = await ItemUseService.use(isar, def: def, realmLookup: repo.getRealm);

    expect(r.kind, ItemUseKind.experienceApplied);
    expect(r.layersGained, 0); // 50 < 100，不升层
    final founder =
        await isar.characters.filter().isFounderEqualTo(true).findFirst();
    expect(founder?.experience, 50); // round(100 × 0.5) = 50
  });

  test('经验丹缩放对比：高 experienceToNextLayer 获得更多 experience', () async {
    // 验证高境界 founder 用同一档丹获得更多绝对经验量（缩放生效）。
    // setup：高 nextLayer=400 的 founder。
    await isar.writeTxn(() async {
      await isar.characters.put(Character.create(
        name: '高境界主角',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.values.first,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026, 1, 1),
        isFounder: true,
        experience: 0,
        experienceToNextLayer: 400, // 高于 seedFounder 的 100
        internalForceMax: 800,
      ));
    });
    await seedItem('item_jingyandan_mid', ItemType.jingYanDan, 1);
    final def = repo.itemDefs['item_jingyandan_mid']!; // layerFraction = 0.5

    await ItemUseService.use(isar, def: def, realmLookup: repo.getRealm);

    final founder =
        await isar.characters.filter().isFounderEqualTo(true).findFirst();
    // gain = round(400 × 0.5) = 200 > 培元丹对低境界(50)的增益。
    expect(founder?.experience, 200);
  });

  test('秘籍：解锁招 + 消费 1', () async {
    await seedFounder();
    await seedItem('item_scroll_kai_bei_shou', ItemType.techniqueScroll, 1);
    final def = repo.itemDefs['item_scroll_kai_bei_shou']!;

    final r = await ItemUseService.use(isar, def: def, realmLookup: repo.getRealm);

    expect(r.kind, ItemUseKind.skillUnlocked);
    final save = await isar.saveDatas.get(0);
    expect(save!.skillUnlockProgress.isUnlocked('skill_kai_bei_shou'), isTrue);
    final item = await isar.inventoryItems.getByDefId('item_scroll_kai_bei_shou');
    expect(item?.quantity ?? 0, 0); // 消费 1 归 0
  });

  test('秘籍幂等：已解锁 → 不消费、返 alreadyKnown', () async {
    await seedFounder();
    await seedItem('item_scroll_kai_bei_shou', ItemType.techniqueScroll, 1);
    final def = repo.itemDefs['item_scroll_kai_bei_shou']!;
    await ItemUseService.use(isar, def: def, realmLookup: repo.getRealm);
    await seedItem('item_scroll_kai_bei_shou', ItemType.techniqueScroll, 1);

    final r = await ItemUseService.use(isar, def: def, realmLookup: repo.getRealm);

    expect(r.kind, ItemUseKind.alreadyKnown);
    final item = await isar.inventoryItems.getByDefId('item_scroll_kai_bei_shou');
    expect(item?.quantity, 1); // 不消费
  });

  test('无库存 → 返 noStock 不写入', () async {
    await seedFounder();
    final def = repo.itemDefs['item_jingyandan_small']!;
    final r = await ItemUseService.use(isar, def: def, realmLookup: repo.getRealm);
    expect(r.kind, ItemUseKind.noStock);
  });

  test('非可用 ItemType（磨剑石）→ 返 notUsable 不消费', () async {
    await seedFounder();
    await seedItem('item_mojianshi', ItemType.moJianShi, 3);
    const def = ItemDef(
      defId: 'item_mojianshi',
      type: ItemType.moJianShi,
      name: '磨剑石',
    );
    final r = await ItemUseService.use(isar, def: def, realmLookup: repo.getRealm);
    expect(r.kind, ItemUseKind.notUsable);
    final item = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(item?.quantity, 3); // 不消费
  });

  test('经验丹但无 founder → 返 noTarget 不消费', () async {
    // 不 seedFounder（只有 IsarSetup.init 建的 SaveData(0)，无 founder 角色）。
    await seedItem('item_jingyandan_small', ItemType.jingYanDan, 2);
    final def = repo.itemDefs['item_jingyandan_small']!;
    final r = await ItemUseService.use(isar, def: def, realmLookup: repo.getRealm);
    expect(r.kind, ItemUseKind.noTarget);
    final item = await isar.inventoryItems.getByDefId('item_jingyandan_small');
    expect(item?.quantity, 2); // 不消费
  });
}
