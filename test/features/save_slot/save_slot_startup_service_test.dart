import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/save_slot/application/save_slot_startup_service.dart';
import 'package:wuxia_idle/features/weapon_codex/domain/equipment_catalog_entry.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_save_slot_startup_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.mainlineProgress.put(
        MainlineProgress()
          ..saveDataId = 1
          ..clearedStageIds = ['stage_01_05']
          ..clearedAt = [DateTime(2026, 2, 1)],
      );
      await isar.equipments.put(
        Equipment.create(
          defId: 'weapon_old',
          tier: EquipmentTier.xunChang,
          slot: EquipmentSlot.weapon,
          obtainedAt: DateTime(2026, 1, 1),
          obtainedFrom: '旧档库存',
        ),
      );
    });
    await IsarSetup.close();
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('底层 init 只打开与迁移数据库，不执行 feature 回填', () async {
    await IsarSetup.init(directory: tempDir, inspector: false);

    expect(await IsarSetup.instance.bossMemorys.count(), 0);
    expect(await IsarSetup.instance.equipmentCatalogEntrys.count(), 0);
  });

  test('openSlot 打开真实槽位后回填 Boss 战绩与兵器谱且保持幂等', () async {
    await SaveSlotStartupService.openSlot(1, directory: tempDir);

    expect(await IsarSetup.instance.bossMemorys.count(), 1);
    expect(await IsarSetup.instance.equipmentCatalogEntrys.count(), 1);

    await SaveSlotStartupService.openSlot(1, directory: tempDir);
    expect(await IsarSetup.instance.bossMemorys.count(), 1);
    expect(await IsarSetup.instance.equipmentCatalogEntrys.count(), 1);
  });

  test('IsarSetup 不反向导入 feature application implementation', () async {
    final source = await File('lib/data/isar_setup.dart').readAsString();

    expect(source, isNot(contains('battle_record/application')));
    expect(source, isNot(contains('weapon_codex/application')));
  });
}
