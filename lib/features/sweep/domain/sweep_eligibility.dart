/// 一键挂机扫荡的门槛判定（纯逻辑，无 Flutter / Isar 依赖）。
///
/// 设计红线（§5.7）：扫荡只在「本周目该单位所有关卡已手工首通」时解锁——
/// 先让玩家真打过一遍，再给省事的一键重打入口。
///
/// 仅依赖原语（关卡 id 串 + 周目号 + 已通关键集合），不依赖 StageDef / Isar，
/// 便于纯函数单测；范围枚举由 provider 层从 GameRepository 注入。
class SweepEligibility {
  const SweepEligibility._();

  /// 主线整章扫荡门槛：本周目（[cycle]）[chapterStageIds] 每关都已通关
  /// （cycleKey `"stageId#cycle"` 命中 [clearedStageCycleKeys]）。
  ///
  /// 空章返回 false（避免 every 对空集返回真值的陷阱）。
  static bool forChapter({
    required List<String> clearedStageCycleKeys,
    required int cycle,
    required List<String> chapterStageIds,
  }) {
    if (chapterStageIds.isEmpty) return false;
    final keys = clearedStageCycleKeys.toSet();
    return chapterStageIds.every((id) => keys.contains('$id#$cycle'));
  }

  /// 爬塔整塔扫荡门槛：本周目已通到满层（[highestClearedFloor] ≥ [floorCount]）。
  /// 注：塔 advanceCycle 后 highestClearedFloor 归 0，故此判定天然按本周目。
  static bool forTower({
    required int highestClearedFloor,
    required int floorCount,
  }) {
    if (floorCount <= 0) return false;
    return highestClearedFloor >= floorCount;
  }
}
