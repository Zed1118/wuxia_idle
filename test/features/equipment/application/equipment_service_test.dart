import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_service.dart';

/// H1 批2 EquipmentService 真 Isar 落地测试(玩家手动装备入口)。
///
/// 不走 testWidgets(真 Isar writeTxn 与 FakeAsync 不兼容 · memory
/// feedback_isar_widget_test_deadlock),用普通 test() 直调 service。
///
/// 用例:
/// - 空槽装备 → success + char.equippedWeaponId == eq.id + eq.ownerCharacterId
/// - 换装 → 旧装回自由池(char slot 指向新装 · 旧装无角色槽指向)
/// - §5.3 境界不达 → lockedByRealm + 0 状态变化
/// - unequip → 槽位 null
/// - 移装(eq 原在他角色槽)→ 他角色槽清空(防双持)
void main() {
  late Directory tempDir;
  late EquipmentService service;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_equip_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    service = EquipmentService(isar: IsarSetup.instance);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<int> seedCharacter({
    RealmTier realmTier = RealmTier.yiLiu,
    int? id,
  }) async {
    final c = Character.create(
      name: '测试角色',
      realmTier: realmTier,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.tianCai,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 5, 30),
    );
    if (id != null) c.id = id;
    return IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.characters.put(c),
    );
  }

  Future<int> seedEquipment({
    EquipmentTier tier = EquipmentTier.xunChang,
    EquipmentSlot slot = EquipmentSlot.weapon,
  }) async {
    final eq = Equipment.create(
      defId: 'test_eq',
      tier: tier,
      slot: slot,
      obtainedAt: DateTime(2026, 5, 30),
      obtainedFrom: 'test',
      baseAttack: 50,
      baseHealth: 100,
      baseSpeed: 10,
    );
    return IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.equipments.put(eq),
    );
  }

  test('空槽装备 → success + 槽位指向 + owner 跟随', () async {
    final cid = await seedCharacter();
    final eid = await seedEquipment(slot: EquipmentSlot.weapon);

    final outcome = await service.equip(characterId: cid, equipmentId: eid);
    expect(outcome, EquipOutcome.success);

    final c = await IsarSetup.instance.characters.get(cid);
    final eq = await IsarSetup.instance.equipments.get(eid);
    expect(c!.equippedWeaponId, eid);
    expect(eq!.ownerCharacterId, cid);
  });

  test('换装 → 旧装回自由池(无角色槽指向旧装)', () async {
    final cid = await seedCharacter();
    final oldId = await seedEquipment(slot: EquipmentSlot.weapon);
    final newId = await seedEquipment(slot: EquipmentSlot.weapon);

    await service.equip(characterId: cid, equipmentId: oldId);
    await service.equip(characterId: cid, equipmentId: newId);

    final c = await IsarSetup.instance.characters.get(cid);
    expect(c!.equippedWeaponId, newId, reason: '槽位应指向新装');
    // 旧装不再被任何角色槽位指向 = 回自由池。
    final all = await IsarSetup.instance.characters.where().findAll();
    final stillHeld = all.any((h) =>
        h.equippedWeaponId == oldId ||
        h.equippedArmorId == oldId ||
        h.equippedAccessoryId == oldId);
    expect(stillHeld, isFalse, reason: '旧装应回自由池');
  });

  test('§5.3 境界不达 → lockedByRealm + 0 状态变化', () async {
    // 学徒角色 vs 神物装备(神物 = 最高阶,远超学徒)。
    final cid = await seedCharacter(realmTier: RealmTier.xueTu);
    final eid =
        await seedEquipment(tier: EquipmentTier.shenWu, slot: EquipmentSlot.weapon);

    final outcome = await service.equip(characterId: cid, equipmentId: eid);
    expect(outcome, EquipOutcome.lockedByRealm);

    final c = await IsarSetup.instance.characters.get(cid);
    final eq = await IsarSetup.instance.equipments.get(eid);
    expect(c!.equippedWeaponId, isNull, reason: '不上身');
    expect(eq!.ownerCharacterId, isNull, reason: 'owner 不变');
  });

  test('unequip → 槽位 null', () async {
    final cid = await seedCharacter();
    final eid = await seedEquipment(slot: EquipmentSlot.armor);
    await service.equip(characterId: cid, equipmentId: eid);

    await service.unequip(characterId: cid, slot: EquipmentSlot.armor);
    final c = await IsarSetup.instance.characters.get(cid);
    expect(c!.equippedArmorId, isNull);
  });

  test('移装 → 原持有角色槽位清空(防双持)', () async {
    final c1 = await seedCharacter();
    final c2 = await seedCharacter();
    final eid = await seedEquipment(slot: EquipmentSlot.weapon);

    await service.equip(characterId: c1, equipmentId: eid);
    await service.equip(characterId: c2, equipmentId: eid);

    final ch1 = await IsarSetup.instance.characters.get(c1);
    final ch2 = await IsarSetup.instance.characters.get(c2);
    expect(ch1!.equippedWeaponId, isNull, reason: 'c1 应被解钩');
    expect(ch2!.equippedWeaponId, eid, reason: 'c2 接装');
  });
}
