import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/weapon_codex/application/equipment_catalog_providers.dart';
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_equipment_catalog_providers_test_');
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

  group('equipmentCatalogListProvider', () {
    test('空存档返回空列表', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final list = await container.read(equipmentCatalogListProvider.future);
      expect(list, isEmpty);
    });

    test('写入 2 条图鉴后，list 长度 == 2', () async {
      final isar = IsarSetup.instance;
      final saveDataId = IsarSetup.currentSlotId;
      final svc = EquipmentCatalogService(isar: isar);

      await svc.recordAcquisitions(
        saveDataId: saveDataId,
        defIds: const ['sword_iron', 'staff_wood'],
        from: 'drop_test',
        now: DateTime(2026, 6, 20),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final list = await container.read(equipmentCatalogListProvider.future);
      expect(list, hasLength(2));
    });
  });

  group('equipmentCatalogCountProvider', () {
    test('空存档 count == 0', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final count = await container.read(equipmentCatalogCountProvider.future);
      expect(count, 0);
    });

    test('写入 2 条图鉴后，count == 2（门控：>0 解锁入口）', () async {
      final isar = IsarSetup.instance;
      final saveDataId = IsarSetup.currentSlotId;
      final svc = EquipmentCatalogService(isar: isar);

      await svc.recordAcquisitions(
        saveDataId: saveDataId,
        defIds: const ['sword_iron', 'staff_wood'],
        from: 'drop_test',
        now: DateTime(2026, 6, 20),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final count = await container.read(equipmentCatalogCountProvider.future);
      expect(count, 2, reason: '>0 即解锁主菜单图鉴入口');
    });
  });
}
