import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/models/character.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/equipment.dart';
import 'package:wuxia_idle/data/models/inventory_item.dart';
import 'package:wuxia_idle/data/models/technique.dart';
import 'package:wuxia_idle/services/phase2_seed_service.dart';

/// T32 子提交 3a：[Phase2SeedService] 真 Isar 落地测试。
///
/// 沿用 [enhancement_persist_test] 的 setUp 套路：临时目录 + IsarSetup.init +
/// GameRepository.loadAllDefs（rootBundle 不可用 → 走文件系统）。
///
/// 5 用例覆盖：
///   - seedP1 → 完整 fixture 字段断言
///   - seedP2 → battleCount=99
///   - seedP3 → 散功前 fixture（IF 10000 + yuanMan/1500 主修 + daCheng 辅修）
///   - seedP4 → 双装备（主 battleCount=2000 / 对照 battleCount=0）
///   - clear 语义：预先脏数据 → seedP1 → 仅余 fixture
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_seed_test_');
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

  Future<int> readQty(ItemType type) async {
    final row = await IsarSetup.instance.inventoryItems
        .filter()
        .itemTypeEqualTo(type)
        .findFirst();
    return row?.quantity ?? 0;
  }

  test('seedP1 → 1 角色 + 1 件 +0 利器装备 + 1000 磨剑石 / 100 心血结晶', () async {
    await Phase2SeedService.seedP1();

    final isar = IsarSetup.instance;
    expect(await isar.characters.count(), 1);
    expect(await isar.equipments.count(), 1);
    expect(await isar.techniques.count(), 0);
    expect(await isar.inventoryItems.count(), 2);

    final ch = await isar.characters.get(1);
    expect(ch, isNotNull);
    expect(ch!.realmTier, RealmTier.erLiu);
    expect(ch.realmLayer, RealmLayer.yuanShu);
    expect(ch.equippedWeaponId, isNotNull);

    final eq = await isar.equipments.get(ch.equippedWeaponId!);
    expect(eq, isNotNull);
    expect(eq!.defId, 'weapon_liqi_long_quan');
    expect(eq.tier, EquipmentTier.liQi);
    expect(eq.slot, EquipmentSlot.weapon);
    expect(eq.enhanceLevel, 0);
    expect(eq.battleCount, 0);
    expect(eq.ownerCharacterId, 1);

    expect(await readQty(ItemType.moJianShi), 1000);
    expect(await readQty(ItemType.xinXueJieJing), 100);
  });

  test('seedP2 → battleCount=99 装备 + 充足材料', () async {
    await Phase2SeedService.seedP2();

    final isar = IsarSetup.instance;
    expect(await isar.equipments.count(), 1);
    final eqs = await isar.equipments.where().findAll();
    expect(eqs.single.battleCount, 99);
    expect(eqs.single.enhanceLevel, 0);
    expect(eqs.single.ownerCharacterId, 1);

    expect(await readQty(ItemType.moJianShi), 2000);
    expect(await readQty(ItemType.xinXueJieJing), 200);
  });

  test('seedP3 → IF 10000 + yuanMan/1500 主修 + daCheng 辅修', () async {
    await Phase2SeedService.seedP3();

    final isar = IsarSetup.instance;
    expect(await isar.characters.count(), 1);
    expect(await isar.equipments.count(), 0);
    expect(await isar.techniques.count(), 2);

    final ch = await isar.characters.get(1);
    expect(ch, isNotNull);
    expect(ch!.internalForce, 10000);
    expect(ch.internalForceMax, 10000);
    expect(ch.school, TechniqueSchool.gangMeng);
    expect(ch.mainTechniqueId, isNotNull);
    expect(ch.assistTechniqueIds.length, 1);

    final main = await isar.techniques.get(ch.mainTechniqueId!);
    expect(main, isNotNull);
    expect(main!.role, TechniqueRole.main);
    expect(main.defId, 'tech_gangmeng_mingjia');
    expect(main.cultivationLayer, CultivationLayer.yuanMan);
    expect(main.cultivationProgress, 1500);
    expect(main.cultivationProgressToNext, 1500); // yuanMan → dianFeng 阈值
    expect(main.ownerCharacterId, 1);

    final assist = await isar.techniques.get(ch.assistTechniqueIds.single);
    expect(assist, isNotNull);
    expect(assist!.role, TechniqueRole.assist);
    expect(assist.defId, 'tech_yinrou_mingjia');
    expect(assist.cultivationLayer, CultivationLayer.daCheng);
    expect(assist.cultivationProgressToNext, 900); // daCheng → yuanMan 阈值
    expect(assist.ownerCharacterId, 1);
  });

  test('seedP4 → 2 件 +0 利器（主 battleCount=2000 已装 / 对照 battleCount=0 未装）',
      () async {
    await Phase2SeedService.seedP4();

    final isar = IsarSetup.instance;
    expect(await isar.characters.count(), 1);
    expect(await isar.equipments.count(), 2);

    final ch = await isar.characters.get(1);
    expect(ch, isNotNull);
    expect(ch!.equippedWeaponId, isNotNull);

    final eqMain = await isar.equipments.get(ch.equippedWeaponId!);
    expect(eqMain, isNotNull);
    expect(eqMain!.battleCount, 2000);
    expect(eqMain.enhanceLevel, 0);
    expect(eqMain.ownerCharacterId, 1);

    final all = await isar.equipments.where().findAll();
    final eqRef = all.firstWhere((e) => e.id != eqMain.id);
    expect(eqRef.battleCount, 0);
    expect(eqRef.enhanceLevel, 0);
    expect(eqRef.ownerCharacterId, isNull, reason: '对照装备未装备，留在背包');

    expect(await readQty(ItemType.moJianShi), 2000);
    expect(await readQty(ItemType.xinXueJieJing), 200);
  });

  test('clear 语义：seedP1 会清掉前一次 seedP3 的全部数据，只留新 fixture', () async {
    await Phase2SeedService.seedP3();
    final isar = IsarSetup.instance;
    expect(await isar.techniques.count(), 2);

    await Phase2SeedService.seedP1();

    expect(await isar.characters.count(), 1);
    expect(await isar.equipments.count(), 1);
    expect(await isar.techniques.count(), 0, reason: 'P3 的 2 本心法应被清空');

    final ch = await isar.characters.get(1);
    expect(ch?.mainTechniqueId, isNull);
    expect(ch?.assistTechniqueIds, isEmpty);

    final eq = await isar.equipments.where().findFirst();
    expect(eq?.defId, 'weapon_liqi_long_quan');
    expect(eq?.battleCount, 0);
  });
}
