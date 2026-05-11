import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/character.dart';
import 'models/equipment.dart';
import 'models/game_event.dart';
import 'models/inventory_item.dart';
import 'models/mainline_progress.dart';
import 'models/retreat_session.dart';
import 'models/save_data.dart';
import 'models/technique.dart';
import 'models/tower_progress.dart';

/// Isar 初始化与生命周期（data_schema.md §7.1，简化版）。
///
/// **Phase 1 简化**：只支持单槽位（slotId=1）。多槽切换 / 列表 / 删除
/// 推迟到 Phase 5（见类内 TODO Phase 5 标注）。
///
/// 文件命名仍按 `wuxia_save_slot{slotId}.isar`，便于 Phase 5 扩展。
class IsarSetup {
  static late Isar instance;
  static int currentSlotId = 1;

  /// 全部持久化 schema 清单（data_schema.md §7.1）。
  ///
  /// Phase 1 起 6 个：SaveData / Character / Equipment / Technique /
  /// InventoryItem / GameEvent。Phase 3 T34 加 MainlineProgress；
  /// Phase 3 T41 加 TowerProgress；Phase 3 T48 加 RetreatSession。
  /// 剩余 AdventureRecord / DailyChallenge 在后续任务建模时追加。
  static const _allSchemas = [
    SaveDataSchema,
    CharacterSchema,
    EquipmentSchema,
    TechniqueSchema,
    InventoryItemSchema,
    GameEventSchema,
    MainlineProgressSchema,
    TowerProgressSchema,
    RetreatSessionSchema,
  ];

  /// 当前 schema 对应的存档版本（写入新建 SaveData.saveVersion）。
  /// Phase 3 T34 schema 加 MainlineProgress collection → 升 0.2.0；
  /// Phase 3 T41 加 TowerProgress collection → 升 0.3.0；
  /// Phase 3 T48 加 RetreatSession collection → 升 0.4.0。
  static const _currentSaveVersion = '0.4.0';

  /// 打开 Isar 实例。`directory` 可注入用于测试；生产由 path_provider 提供。
  static Future<void> init({
    int slotId = 1,
    Directory? directory,
    bool inspector = true,
  }) async {
    assert(slotId >= 1 && slotId <= 3, 'slotId 必须是 1/2/3');

    final dir = directory ?? await getApplicationDocumentsDirectory();
    instance = await Isar.open(
      _allSchemas,
      directory: dir.path,
      name: 'wuxia_save_slot$slotId',
      inspector: inspector,
    );
    currentSlotId = slotId;

    await _ensureSaveData();
  }

  /// 启动时确保 SaveData 单例存在；不存在则建一行默认值。
  static Future<SaveData> _ensureSaveData() async {
    final existing = await instance.saveDatas.get(0);
    if (existing != null) return existing;

    final now = DateTime.now();
    final fresh = SaveData()
      ..id = 0
      ..slotId = currentSlotId
      ..saveVersion = _currentSaveVersion
      ..createdAt = now
      ..lastSavedAt = now
      ..lastOnlineAt = now;
    await instance.writeTxn(() => instance.saveDatas.put(fresh));
    return fresh;
  }

  static Future<void> close() async {
    await instance.close();
  }

  // TODO Phase 5: switchSlot(int newSlotId) — 切换存档槽位
  // TODO Phase 5: listAllSlots() — 存档选择界面用
  // TODO Phase 5: deleteSlot(int slotId) — 删除指定槽位
}
