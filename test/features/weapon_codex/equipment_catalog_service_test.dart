import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/weapon_codex/application/equipment_catalog_service.dart';

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
    tempDir = await Directory.systemTemp.createTemp('wuxia_weapon_codex_test_');
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

  Future<void> putInventory(Isar isar, String defId) async {
    await isar.writeTxn(() async {
      await isar.equipments.put(
        Equipment.create(
          defId: defId,
          tier: EquipmentTier.xunChang,
          slot: EquipmentSlot.weapon,
          obtainedAt: DateTime(2026, 1, 1),
          obtainedFrom: '库存',
        ),
      );
    });
  }

  group('EquipmentCatalogService.recordAcquisitions', () {
    test('首得建档', () async {
      final svc = EquipmentCatalogService(isar: IsarSetup.instance);
      final t1 = DateTime(2026, 6, 19);
      await svc.recordAcquisitions(
        saveDataId: 1,
        defIds: ['weapon_a'],
        from: '黑风寨之战',
        now: t1,
      );
      final e = await svc.entryFor(1, 'weapon_a');
      expect(e, isNotNull);
      expect(e!.firstObtainedAt, t1);
      expect(e.firstObtainedFrom, '黑风寨之战');
      expect(e.obtainedCount, 1);
      expect(e.isPreRecord, isFalse);
    });

    test('重得累加不覆盖首得快照', () async {
      final svc = EquipmentCatalogService(isar: IsarSetup.instance);
      final t1 = DateTime(2026, 6, 19);
      final t2 = DateTime(2026, 6, 20);
      await svc.recordAcquisitions(
        saveDataId: 1,
        defIds: ['weapon_a'],
        from: '黑风寨之战',
        now: t1,
      );
      await svc.recordAcquisitions(
        saveDataId: 1,
        defIds: ['weapon_a'],
        from: '宝塔第3层',
        now: t2,
      );
      final e = await svc.entryFor(1, 'weapon_a');
      expect(e, isNotNull);
      expect(e!.obtainedCount, 2);
      expect(e.firstObtainedFrom, '黑风寨之战', reason: '首得快照冻结');
      expect(e.firstObtainedAt, t1, reason: '首得时间不覆盖');
    });
  });

  group('EquipmentCatalogService.reconcileFromInventory', () {
    test('未入册库存回填为 preRecord 来历不详', () async {
      final svc = EquipmentCatalogService(isar: IsarSetup.instance);
      await putInventory(IsarSetup.instance, 'weapon_old');
      await svc.reconcileFromInventory(1);
      final e = await svc.entryFor(1, 'weapon_old');
      expect(e, isNotNull);
      expect(e!.isPreRecord, isTrue);
      expect(e.firstObtainedFrom, EquipmentCatalogService.backfillSource);
      expect(e.firstObtainedFrom, '来历不详');
      expect(e.firstObtainedAt, isNull);
    });

    test('已入册档不被 reconcile 降级', () async {
      final svc = EquipmentCatalogService(isar: IsarSetup.instance);
      await svc.recordAcquisitions(
        saveDataId: 1,
        defIds: ['weapon_a'],
        from: '真来源',
        now: DateTime(2026, 6, 19),
      );
      await putInventory(IsarSetup.instance, 'weapon_a');
      await svc.reconcileFromInventory(1);
      final e = await svc.entryFor(1, 'weapon_a');
      expect(e, isNotNull);
      expect(e!.isPreRecord, isFalse, reason: '已入册不降级');
      expect(e.firstObtainedFrom, '真来源', reason: '来源不被覆盖');
    });
  });
}
