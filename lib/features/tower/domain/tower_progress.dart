import 'package:isar_community/isar.dart';

part 'tower_progress.g.dart';

/// 爬塔进度（Phase 3 T41）。
///
/// **每存档单行**：与 SaveData 一对一关联（Phase 3 仅 saveDataId=1）。
/// Phase 5 多存档时按 saveDataId 索引筛。
///
/// 设计取舍（phase3_tasks Week 2 拍板）：
///   - 不退层：失败保留 [highestClearedFloor]，无限重试（与主线 onDefeat 一致）
///   - 永久记录：无重置、无赛季（GDD §5.1 反主流，§12 也未列）
///   - 重打不发奖：[TowerProgressService.recordClear] 返回 isFirstClear bool，
///     UI 端在 isFirstClear == true 时才走 [DropService.rollTowerRewards]
///   - 不存 run-by-run 细节：Demo 阶段只关心「最高层 + 总览统计」，
///     按层的击杀回合/掉落明细等留 Phase 4+ 再决定要不要存
@collection
class TowerProgress {
  Id id = Isar.autoIncrement;

  /// 关联 SaveData.slotId（Phase 3 固定 1）。Phase 5 多存档不建 unique index，
  /// 一个 saveDataId 一行（service 层保证）。
  late int saveDataId;

  /// 已通的最高层号，0 = 一层未通；1-30 = 已通到该层（含）。
  /// 单调递增（recordClear 只在 floorIndex == highestClearedFloor + 1 时 ++）。
  int highestClearedFloor = 0;

  /// 最高层首通时间。highestClearedFloor == 0 时为 null。
  DateTime? highestClearedAt;

  /// 累计尝试次数（首通 + 重打 + 失败都算）。
  int totalAttempts = 0;

  /// 累计失败次数。
  int totalDefeats = 0;

  /// 进度行创建时间（首次 getOrCreate 时记录）。
  late DateTime createdAt;

  /// 各层首通耗时（ms），index = floorIndex - 1。
  /// 第 N 层首通后写 perFloorClearTimes[N-1] = elapsedMs;
  /// 重打不覆盖（锁首通耗时，防玩家强化后刷新数据，GDD §5.1 反主流）。
  /// 跳层后空位补 0,bestClearTime 派生时过滤 0。
  List<int> perFloorClearTimes = [];

  /// 全塔最佳通关耗时（ms,即 perFloorClearTimes 非 0 值的 min）。
  /// 派生字段,recordClear 时同步计算。null = 无通关数据。
  int? bestClearTime;

  /// 最近一次通关时间（任何层 + 首通/重打都更新）。
  /// 与 highestClearedAt（只锁首通最高层）区分。
  DateTime? lastClearedAt;
}
