import 'package:isar/isar.dart';

part 'save_data.g.dart';

/// 全局存档元数据（data_schema.md §4.1）。
///
/// **每槽单例**：每个存档槽位对应独立的 Isar db 文件，每个 db 内 SaveData
/// 只有一行，`id` 固定为 0。多存档完全隔离。
///
/// Phase 1 简化：只用 slotId=1，多槽切换推迟到 Phase 5。
@collection
class SaveData {
  /// 每个槽位 db 文件内单例（id 固定为 0）。
  Id id = 0;

  /// 存档槽位号，与 db 文件名 `wuxia_save_slot{slotId}` 对应。冗余存储以
  /// 便存档选择界面快速识别。Phase 1 只用 1。
  int slotId = 1;

  /// 玩家自定义存档名，存档选择界面展示用。
  String? slotName;

  /// 存档版本（semver）。未来 schema migration 用 major.minor 判断。
  late String saveVersion;

  late DateTime createdAt;
  late DateTime lastSavedAt;

  /// 最后在线时间，离线挂机用，玩家关游戏时写入。
  late DateTime lastOnlineAt;

  String? sectName;
  int? founderCharacterId;

  /// 当前出战阵容（FK → Character.id），长度 ≤3。
  List<int> activeCharacterIds = [];

  int totalPlaySeconds = 0;
  bool isOnboardingCompleted = false;
  int highestTowerLayer = 0;

  DateTime? towerLeaderboardSyncedAt;
}
