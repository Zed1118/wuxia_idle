/// 半手动战斗 P0 步骤5:一场战斗的进入模式(入口决策)。
///
/// 真实入口(`_StageBattleHost` / `_TowerBattleHost`)进战斗前由
/// [resolveAutoPlayMode] 算出本场模式,据此构造 BattleScreen(manualStep
/// 或 replayOps)+ 选 seed + 决定胜利是否录制。
enum AutoPlayMode {
  /// 未通关:强制手动单步,胜利后录 seed+ops(用户拍板#1 全部战斗关首通手动)。
  manualFirstClear,

  /// 已通关但玩家选手动(override=false 或全局关):手动重打,胜利后覆盖录制。
  manualReplay,

  /// 已通关 + 有记录 + 自动:用 seed+ops 确定性重演(`BattleNotifier.replay`)。
  autoReplay,

  /// 迁移豁免(已通关无记录)+ 自动:走现有自动战斗(无 seed 记录,用户拍板#4)。
  autoFallback,
}

/// 决策真相表。`autoWanted = override ?? globalDefault`。
///
/// - [isCleared]:该关该周目是否已通关(主线 clearedStageIds / 塔 highestClearedFloor)。
/// - [hasRecord]:是否有 BattleReplayRecord(手动通关落盘过 → 可 replay)。
/// - [override]:每关记忆(`BattleReplayRecord.autoPlayOverride`),null=随全局。
/// - [globalDefault]:全局 `GameplaySettings.autoPlayDefault`。
AutoPlayMode resolveAutoPlayMode({
  required bool isCleared,
  required bool hasRecord,
  required bool? override,
  required bool globalDefault,
}) {
  if (!isCleared) return AutoPlayMode.manualFirstClear;
  final autoWanted = override ?? globalDefault;
  if (!autoWanted) return AutoPlayMode.manualReplay;
  return hasRecord ? AutoPlayMode.autoReplay : AutoPlayMode.autoFallback;
}
