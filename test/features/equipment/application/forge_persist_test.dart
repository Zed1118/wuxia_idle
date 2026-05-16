import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/features/equipment/application/forging_service.dart';

/// T32 #22b ForgingService.persistResult 真 Isar 落地测试。
///
/// 不依赖 Flutter binding，普通 `test()`：setUp 临时目录 + IsarSetup.init +
/// seed 装备（enhanceLevel 已满足开锋 slot 1 解锁）→ forge → persistResult →
/// 关闭再读，断言 forgingSlots[0] unlocked / type / bonusValue 字段都落地。
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_forge_persist_');
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

  Future<Equipment> seedEq({int enhanceLevel = 10}) async {
    final eq = Equipment.create(
      defId: 'test_eq',
      tier: EquipmentTier.liQi,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 5, 11),
      obtainedFrom: 'test',
      baseAttack: 200,
      enhanceLevel: enhanceLevel,
    );
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.equipments.put(eq);
    });
    return eq;
  }

  test('forge success → persistResult 后 forgingSlots[0] 已落地 Isar', () async {
    final eq = await seedEq(enhanceLevel: 10);
    final def = GameRepository.instance.equipmentDefs.values.first;
    final config = GameRepository.instance.numbers.forging;

    final result = ForgingService.forge(
      eq: eq,
      def: def,
      slotIndex: 1,
      type: ForgingSlotType.attack,
      config: config,
    );
    expect(result, ForgeResult.success);
    expect(eq.forgingSlots[0].unlocked, isTrue);
    expect(eq.forgingSlots[0].type, ForgingSlotType.attack);

    await ForgingService(isar: IsarSetup.instance).persistResult(
      eq: eq,
    );

    // 关闭再开,确认真落盘
    await IsarSetup.close();
    await IsarSetup.init(directory: tempDir, inspector: false);
    final eqBack = await IsarSetup.instance.equipments.get(eq.id);
    expect(eqBack, isNotNull);
    expect(eqBack!.forgingSlots[0].unlocked, isTrue);
    expect(eqBack.forgingSlots[0].type, ForgingSlotType.attack);
    expect(eqBack.forgingSlots[0].bonusValue, eq.forgingSlots[0].bonusValue);
  });

  test('forge 后 enhanceLevel 不变（开锋无升级语义）', () async {
    final eq = await seedEq(enhanceLevel: 15);
    final def = GameRepository.instance.equipmentDefs.values.first;
    final config = GameRepository.instance.numbers.forging;

    final available = ForgingService.availableTypesForSlot(
      eq: eq,
      slotIndex: 1,
      config: config,
    );
    expect(available, isNotEmpty);
    final result = ForgingService.forge(
      eq: eq,
      def: def,
      slotIndex: 1,
      type: available.first,
      config: config,
    );
    expect(result, ForgeResult.success);

    await ForgingService(isar: IsarSetup.instance).persistResult(
      eq: eq,
    );

    final eqBack = await IsarSetup.instance.equipments.get(eq.id);
    expect(eqBack?.enhanceLevel, 15, reason: '开锋不改 enhanceLevel');
  });
}
