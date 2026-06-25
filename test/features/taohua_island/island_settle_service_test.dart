import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_settle_service.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_type.dart';

/// IslandSettleService Isar 落地测试。
///
/// 体例沿 encounter_service_test：setUpAll 加载 GameRepository
/// （numbers.yaml taohuaIsland 段），setUp 临时目录 + IsarSetup.init。
/// 使用 test()（非 testWidgets()）避免 Isar writeTxn 死锁。

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_island_settle_');
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

  // ── helper：插入祖师角色并更新 save 字段 ───────────────────────────────
  Future<void> seedFounder({RealmTier tier = RealmTier.xueTu}) async {
    final isar = IsarSetup.instance;
    final founder = Character.create(
      name: '祖师',
      realmTier: tier,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime.now(),
    )..isFounder = true;

    await isar.writeTxn(() async {
      final id = await isar.characters.put(founder);
      final save = (await isar.saveDatas.get(0))!;
      save.founderCharacterId = id;
      save.activeCharacterIds = [id];
      await isar.saveDatas.put(save);
    });
  }

  // ── T1: ensureInitialized：空 islandBuildings → 建 4 建筑 ──────────────
  test('T1: ensureInitialized 空档→建 4 建筑、processor 有默认 activeRecipeId、时间被设', () async {
    await seedFounder();
    final isar = IsarSetup.instance;
    final save = (await isar.saveDatas.get(0))!;
    final now = DateTime(2026, 6, 25, 10, 0);

    expect(save.islandBuildings, isEmpty);
    expect(save.islandLastSettledAt, isNull);

    await IslandSettleService.ensureInitialized(save, now);

    final updated = (await isar.saveDatas.get(0))!;
    expect(updated.islandBuildings.length, 4,
        reason: '4 个建筑（2 source + 2 processor）');

    // processor 有默认 activeRecipeId
    final daZaoTai = updated.islandBuildings
        .where((b) => b.type == BuildingType.daZaoTai)
        .firstOrNull;
    expect(daZaoTai, isNotNull);
    expect(daZaoTai!.activeRecipeId, 'forge_mojianshi');

    final danFang = updated.islandBuildings
        .where((b) => b.type == BuildingType.danFang)
        .firstOrNull;
    expect(danFang, isNotNull);
    expect(danFang!.activeRecipeId, 'brew_ningshen');

    // source 无 activeRecipeId
    final tieJiangChang = updated.islandBuildings
        .where((b) => b.type == BuildingType.tieJiangChang)
        .firstOrNull;
    expect(tieJiangChang!.activeRecipeId, isNull);

    // islandLastSettledAt 被写入
    expect(updated.islandLastSettledAt, now);
  });

  // ── T2: ensureInitialized：已初始化 → 不改动 ──────────────────────────
  test('T2: ensureInitialized 已初始化→不改动已有建筑', () async {
    await seedFounder();
    final isar = IsarSetup.instance;
    final now1 = DateTime(2026, 6, 25, 10, 0);
    final now2 = DateTime(2026, 6, 25, 12, 0);

    // 先初始化一次
    final save = (await isar.saveDatas.get(0))!;
    await IslandSettleService.ensureInitialized(save, now1);

    // 读回，手动改第一个建筑 level 为 3
    await isar.writeTxn(() async {
      final s = (await isar.saveDatas.get(0))!;
      s.islandBuildings[0].level = 3;
      await isar.saveDatas.put(s);
    });

    // 再次 ensureInitialized → 不应重建
    final save2 = (await isar.saveDatas.get(0))!;
    await IslandSettleService.ensureInitialized(save2, now2);

    final updated = (await isar.saveDatas.get(0))!;
    expect(updated.islandBuildings[0].level, 3,
        reason: '已初始化不应重置 level');
    expect(updated.islandLastSettledAt, now1,
        reason: '已初始化不应更新时间');
  });

  // ── T3: settle：storage 增长、time 更新、inventory 不变 ──────────────────
  test('T3: settle N 小时→ storage 增长、islandLastSettledAt 更新、inventory 不变', () async {
    await seedFounder(tier: RealmTier.xueTu);
    final isar = IsarSetup.instance;
    final past = DateTime(2026, 6, 25, 0, 0);
    final now = DateTime(2026, 6, 25, 4, 0); // 4 小时后

    // 先初始化
    final save = (await isar.saveDatas.get(0))!;
    await IslandSettleService.ensureInitialized(save, past);

    // 再 settle
    final save2 = (await isar.saveDatas.get(0))!;
    await IslandSettleService.settle(save2, now);

    final updated = (await isar.saveDatas.get(0))!;
    // 打造台（processor）4h × 1.5/h × level1 = 6 磨剑石（铁匠厂原料 24 精铁被消耗）
    final daZaoState = updated.islandBuildings
        .firstWhere((b) => b.type == BuildingType.daZaoTai);
    expect(daZaoState.stored, greaterThan(0),
        reason: '打造台 4h 应有成品 storage（消耗铁匠厂精铁产磨剑石）');

    // islandLastSettledAt 更新
    expect(updated.islandLastSettledAt, now);

    // inventory 不变（settle 不入背包）
    final inv = await isar.inventoryItems.where().findAll();
    expect(inv, isEmpty, reason: 'settle 不写 inventory');
  });

  // ── T4: harvest：成品入背包、stored 清小数尾、IslandHarvest 有条目 ────────
  test('T4: harvest→ InventoryItem 增加、stored 清到小数尾、IslandHarvest.gained 非空', () async {
    await seedFounder(tier: RealmTier.xueTu);
    final isar = IsarSetup.instance;
    final past = DateTime(2026, 6, 25, 0, 0);
    final now = DateTime(2026, 6, 25, 24, 0); // 24 小时后，保证有成品

    final save = (await isar.saveDatas.get(0))!;
    await IslandSettleService.ensureInitialized(save, past);

    final save2 = (await isar.saveDatas.get(0))!;
    final harvest = await IslandSettleService.harvest(save2, now);

    // IslandHarvest 非空
    expect(harvest.isEmpty, isFalse, reason: '24h 应有成品');

    // InventoryItem 有数量
    final items = await isar.inventoryItems.where().findAll();
    expect(items.isNotEmpty, isTrue, reason: 'harvest 后 inventory 应有条目');

    final totalQty = items.fold<int>(0, (sum, i) => sum + i.quantity);
    expect(totalQty, greaterThan(0));

    // stored 清到小数尾（floor 后余量 ∈ [0, 1)）
    final updated = (await isar.saveDatas.get(0))!;
    for (final b in updated.islandBuildings) {
      expect(b.stored >= 0 && b.stored < 1.0, isTrue,
          reason: '${b.type} stored=${b.stored} 应已 floor 清走整数部分');
    }
  });

  // ── T5: offline 长时段 harvest：多建筑成品齐全 ────────────────────────────
  test('T5: 长时段(72h)harvest→ 多建筑成品(磨剑石+凝神丹)同时出现在 gained', () async {
    await seedFounder(tier: RealmTier.xueTu);
    final isar = IsarSetup.instance;
    final past = DateTime(2026, 6, 25, 0, 0);
    // 72h：封顶时长，两个加工建筑都应有成品
    final now = DateTime(2026, 6, 25, 0, 0).add(const Duration(hours: 72));

    final save = (await isar.saveDatas.get(0))!;
    await IslandSettleService.ensureInitialized(save, past);

    final save2 = (await isar.saveDatas.get(0))!;
    final harvest = await IslandSettleService.harvest(save2, now);

    // 两种成品都应出现
    expect(harvest.gained.containsKey('item_mojianshi'), isTrue,
        reason: '打造台 72h 应产磨剑石');
    expect(harvest.gained.containsKey('item_jingyandan_small'), isTrue,
        reason: '丹房 72h 应产凝神丹');

    // 每种数量 > 0
    expect(harvest.gained['item_mojianshi']!, greaterThan(0));
    expect(harvest.gained['item_jingyandan_small']!, greaterThan(0));

    // InventoryItem 有对应条目
    final mojianshi = await isar.inventoryItems.getByDefId('item_mojianshi');
    final jingyandan = await isar.inventoryItems.getByDefId('item_jingyandan_small');
    expect(mojianshi?.quantity, greaterThan(0));
    expect(jingyandan?.quantity, greaterThan(0));
  });

  // ── T6: harvest 累加——第二次 harvest 叠加在第一次数量上 ─────────────────
  test('T6: 两次 harvest→ InventoryItem quantity 累加', () async {
    await seedFounder(tier: RealmTier.xueTu);
    final isar = IsarSetup.instance;
    final t0 = DateTime(2026, 6, 25, 0, 0);
    final t1 = t0.add(const Duration(hours: 12));
    final t2 = t1.add(const Duration(hours: 12));

    final save = (await isar.saveDatas.get(0))!;
    await IslandSettleService.ensureInitialized(save, t0);

    final save2 = (await isar.saveDatas.get(0))!;
    final h1 = await IslandSettleService.harvest(save2, t1);

    final save3 = (await isar.saveDatas.get(0))!;
    final h2 = await IslandSettleService.harvest(save3, t2);

    // 强制断言：两次 harvest 都必须产出 mojianshi，否则测试场景静默空跑
    expect(h1.gained.containsKey('item_mojianshi'), isTrue,
        reason: '首次 harvest 应有磨剑石');
    expect(h2.gained.containsKey('item_mojianshi'), isTrue,
        reason: '二次 harvest 应有磨剑石');

    // 累加量断言
    final item = await isar.inventoryItems.getByDefId('item_mojianshi');
    final expected =
        (h1.gained['item_mojianshi']!) + (h2.gained['item_mojianshi']!);
    expect(item?.quantity, expected, reason: '两次 harvest 数量应累加');
  });

  // ── T7: founder 不存在时 realmIndex fallback 0 ─────────────────────────
  test('T7: 无 founder → founderRealmIndex=0 fallback 不崩', () async {
    // 不调 seedFounder，直接 settle（无 active 角色）
    final isar = IsarSetup.instance;
    final past = DateTime(2026, 6, 25, 0, 0);
    final now = DateTime(2026, 6, 25, 4, 0);

    final save = (await isar.saveDatas.get(0))!;
    await IslandSettleService.ensureInitialized(save, past);

    final save2 = (await isar.saveDatas.get(0))!;
    // 应不崩，正常完成
    await IslandSettleService.settle(save2, now);

    final updated = (await isar.saveDatas.get(0))!;
    expect(updated.islandLastSettledAt, now);
  });

  // ── T8: founderRealmIndex 公开化——直接调用返回正确 index ─────────────────
  test('T8: founderRealmIndex public helper：有 founder 时返回正确 realmTier.index', () async {
    await seedFounder(tier: RealmTier.erLiu); // erLiu = 二流，index 应为 2
    final isar = IsarSetup.instance;
    final save = (await isar.saveDatas.get(0))!;

    final idx = await IslandSettleService.founderRealmIndex(save);
    // RealmTier.erLiu.index 根据 enum 顺序：xueTu=0, sanLiu=1, erLiu=2
    expect(idx, RealmTier.erLiu.index,
        reason: 'founderRealmIndex 公开化后应与 founder.realmTier.index 一致');
    expect(idx, 2, reason: '二流境界 index=2');
  });
}
