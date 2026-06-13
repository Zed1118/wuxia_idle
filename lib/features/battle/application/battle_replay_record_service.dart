import 'package:isar_community/isar.dart';

import '../domain/battle_replay.dart';
import '../domain/battle_replay_record.dart';

/// 半手动战斗 P0 步骤5:重放落盘 service(spec §五 P0#5)。
///
/// 手动单步通关后 [record] 写 `{battleKey, seed, ops}`;自动战斗前 [find] /
/// [isManuallyCleared] 查该关该周目是否已手动通关(存在性 = 已通 → 解锁自动)。
/// 自动执行用读出的 seed + ops 走 `BattleNotifier.replay` 确定性复刻(步骤4)。
///
/// **每存档单行 per battleKey**:无 unique index,service 层 find-then-put 保证
/// (Phase 1 仅 saveDataId=1)。重复手动通关覆盖为最新 seed+ops。
///
/// **范围**(用户拍板 2026-06-13):本波纯落盘地基;真实入口(stage/tower)接
/// manualStep 首通 + 自动开关 UI + replay 自动执行 wiring 留下一波。
class BattleReplayRecordService {
  const BattleReplayRecordService({required this.isar});

  final Isar isar;

  /// 主线关 battleKey:`stage#<stageId>#<cycle>`。cycle 默认 1(P0 无周目)。
  static String stageBattleKey(String stageId, {int cycle = 1}) =>
      'stage#$stageId#$cycle';

  /// 爬塔层 battleKey:`tower#<floor>#<cycle>`。cycle 默认 1。
  static String towerBattleKey(int floor, {int cycle = 1}) =>
      'tower#$floor#$cycle';

  /// 查该 battleKey 的重放记录;无则 null。
  Future<BattleReplayRecord?> find(
    String battleKey, {
    int saveDataId = 1,
  }) =>
      isar.battleReplayRecords
          .filter()
          .saveDataIdEqualTo(saveDataId)
          .battleKeyEqualTo(battleKey)
          .findFirst();

  /// 该 battleKey 是否已手动通关(记录存在性)。
  Future<bool> isManuallyCleared(
    String battleKey, {
    int saveDataId = 1,
  }) async =>
      (await find(battleKey, saveDataId: saveDataId)) != null;

  /// 手动通关写记录。同 battleKey 已有 → 覆盖为最新 seed+ops+clearedAt(单行)。
  /// [clearedAt] 可注入(测试确定性);省略用 `DateTime.now()`。
  Future<void> record({
    required String battleKey,
    required int seed,
    required List<BattleReplayOp> ops,
    int saveDataId = 1,
    DateTime? clearedAt,
  }) async {
    await isar.writeTxn(() async {
      final existing = await find(battleKey, saveDataId: saveDataId);
      final rec = existing ?? BattleReplayRecord();
      rec
        ..saveDataId = saveDataId
        ..battleKey = battleKey
        ..seed = seed
        ..opsJson = BattleReplayOp.encodeList(ops)
        ..clearedAt = clearedAt ?? DateTime.now();
      await isar.battleReplayRecords.put(rec);
    });
  }
}
