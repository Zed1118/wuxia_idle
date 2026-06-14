import 'package:isar_community/isar.dart';

part 'mainline_progress.g.dart';

/// 主线进度（Phase 3 T34）。
///
/// **每存档单行**：与 SaveData 一对一关联（Phase 3 仅 saveDataId=1）。
/// Phase 5 多存档时按 saveDataId 索引筛。
///
/// 设计取舍：
///   - `clearedStageIds` 与 `clearedAt` 同序约定，append-only；重复通关不
///     重复 append（service 在 recordVictory 内幂等判定）
///   - **不存** 难度 / exp / loot —— 那些算战斗结算职责，进度只管「通没通」
///   - `currentChapterIndex` 是玩家当前焦点章节（UI 默认展开 / 后续提示用），
///     与「该章是否已通关」是两个独立维度
@collection
class MainlineProgress {
  Id id = Isar.autoIncrement;

  /// 关联 SaveData.slotId（Phase 3 固定 1）。Phase 5 多存档不建 unique index，
  /// 一个 saveDataId 一行（service 层保证）。
  late int saveDataId;

  /// 当前焦点章节（玩家最后进入的章节）。默认 1。
  int currentChapterIndex = 1;

  /// 已通关 stage id 列表（无序集合语义，append-only）。
  List<String> clearedStageIds = [];

  /// 与 [clearedStageIds] 同序的首通时间。同长度约定由 service 维护。
  List<DateTime> clearedAt = [];

  /// 每关每周目已手动通关键集合,每条 `"stageId#cycle"`(append-only 无序集合)。
  /// cycle1 解锁链仍用 [clearedStageIds];本字段管周目维度(P1 周目进化)。
  /// 注:2026-06-14 周目改按章后,本字段保留向后兼容(Boss 招降等 per-stage
  /// 逻辑仍读),但周目解锁/选择改由 [clearedChapterCycleKeys] 承载。
  List<String> clearedStageCycleKeys = [];

  /// 每章每周目已通关键集合,每条 `"<chapterKey>#cycle"`(append-only 无序集合)。
  /// chapterKey:主线 `"ch1".."ch6"`,副本 `stageType.name`(innerDemon/lightFoot/
  /// massBattle)。仅在该章/副本**章末 Boss 关**(isBoss)某周目通关时写入 →
  /// 「通关整章 Boss 才解锁下一周目」(2026-06-14 周目按章)。
  /// saveVersion 0.21.0→0.22.0 迁移自旧 [clearedStageCycleKeys] 的 Boss 关条目。
  List<String> clearedChapterCycleKeys = [];
}
