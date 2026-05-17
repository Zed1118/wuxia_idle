import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../core/domain/character.dart';
import '../features/encounter/domain/encounter_progress.dart';
import '../core/domain/equipment.dart';
import '../core/domain/game_event.dart';
import '../core/domain/inventory_item.dart';
import '../features/mainline/domain/mainline_progress.dart';
import '../features/seclusion/domain/retreat_session.dart';
import '../core/domain/save_data.dart';
import '../core/domain/technique.dart';
import '../features/tower/domain/tower_progress.dart';

/// Isar 初始化与生命周期（data_schema.md §7.1，简化版）。
///
/// **Phase 1 简化**：只支持单槽位（slotId=1）。多槽切换 / 列表 / 删除
/// 推迟到 Phase 5（见类内 TODO Phase 5 标注）。
///
/// 文件命名仍按 `wuxia_save_slot{slotId}.isar`，便于 Phase 5 扩展。
class IsarSetup {
  static Isar? _instance;

  /// 已初始化的 Isar 实例（生产路径用）。未 init 时抛 [StateError],
  /// 强制调用方先跑 [init]。
  static Isar get instance =>
      _instance ??
      (throw StateError('IsarSetup 未初始化,请先 await IsarSetup.init()'));

  /// 探测式 getter（Phase 5 W6-S2 引入,供 [isarProvider] 走 nullable
  /// propagation）：未 init 时返回 null,不抛错。生产路径走 [instance]。
  static Isar? get instanceOrNull => _instance;

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
    EncounterProgressSchema,
  ];

  /// 当前 schema 对应的存档版本（写入新建 SaveData.saveVersion）。
  /// Phase 3 T34 schema 加 MainlineProgress collection → 升 0.2.0；
  /// Phase 3 T41 加 TowerProgress collection → 升 0.3.0；
  /// Phase 3 T48 加 RetreatSession collection → 升 0.4.0。
  /// Phase 4 W14-1 加 EncounterProgress collection → 升 0.5.0。
  /// Phase 4 W14-2 EncounterProgress 加 biomeMinutes/weatherMinutes 嵌入 → 升 0.6.0。
  /// Phase 4 W14-3-A Character 加 equippedEncounterSkillId String? → 升 0.7.0。
  /// W15 #30 第 2 期 Character 加 insightPoints int(领悟点 wallet) → 升 0.8.0。
  /// P0.2 #40 Phase 1 TowerProgress 加 perFloorClearTimes/bestClearTime/lastClearedAt → 升 0.9.0。
  /// P1 #42 Phase 1 SaveData 加 tutorialStep(留 §10 P1.x 接口)→ 升 0.10.0。
  static const _currentSaveVersion = '0.10.0';

  /// 打开 Isar 实例。`directory` 可注入用于测试；生产由 path_provider 提供。
  static Future<void> init({
    int slotId = 1,
    Directory? directory,
    bool inspector = true,
  }) async {
    assert(slotId >= 1 && slotId <= 3, 'slotId 必须是 1/2/3');

    final dir = directory ?? await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
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
    final isar = instance;
    final existing = await isar.saveDatas.get(0);
    if (existing != null) return existing;

    final now = DateTime.now();
    final fresh = SaveData()
      ..id = 0
      ..slotId = currentSlotId
      ..saveVersion = _currentSaveVersion
      ..createdAt = now
      ..lastSavedAt = now
      ..lastOnlineAt = now;
    await isar.writeTxn(() => isar.saveDatas.put(fresh));
    return fresh;
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }

  // TODO Phase 5: switchSlot(int newSlotId) — 切换存档槽位
  // TODO Phase 5: listAllSlots() — 存档选择界面用
  // TODO Phase 5: deleteSlot(int slotId) — 删除指定槽位
}
