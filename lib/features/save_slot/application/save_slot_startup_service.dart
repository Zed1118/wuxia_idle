import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../data/isar_setup.dart';
import '../../battle_record/application/boss_memory_service.dart';
import '../../weapon_codex/application/equipment_catalog_service.dart';

/// 打开存档槽并执行 feature 启动维护。
///
/// 数据库生命周期、迁移与恢复由 [IsarSetup] 负责；依赖 feature application
/// implementation 的幂等回填集中在本编排层，单项失败沿既有策略不阻塞进档。
class SaveSlotStartupService {
  const SaveSlotStartupService._();

  static Future<void> openSlot(int slotId, {Directory? directory}) async {
    await IsarSetup.switchSlot(slotId, directory: directory);
    await runFeatureMaintenance();
  }

  @visibleForTesting
  static Future<void> runFeatureMaintenance() async {
    final isar = IsarSetup.instance;
    final slotId = IsarSetup.currentSlotId;

    try {
      await BossMemoryService(isar: isar).backfillFromProgress(slotId);
    } catch (error) {
      debugPrint('SaveSlotStartupService: BossMemory 回填 skip(不阻塞启动): $error');
    }

    try {
      await EquipmentCatalogService(isar: isar).reconcileFromInventory(slotId);
    } catch (error) {
      debugPrint(
        'SaveSlotStartupService: EquipmentCatalog 回填 skip(不阻塞启动): '
        '$error',
      );
    }
  }
}
