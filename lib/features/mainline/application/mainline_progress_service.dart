import 'package:isar_community/isar.dart';

import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/enums.dart';
import '../../tutorial/application/tutorial_service.dart';
import '../domain/mainline_progress.dart';

/// 单条章节关卡 + 解锁状态（[MainlineProgressService.availableStages] 返回值）。
typedef StageEntry = ({StageDef def, StageStatus status});

/// 主线进度服务（Phase 3 T34）。
///
/// 职责：
///   - getOrCreate：幂等获取/创建当前存档的 [MainlineProgress] 单行
///   - availableStages：按章节返回该章所有 stage + 三态（locked/available/cleared）
///   - recordVictory：首通 append 到 clearedStageIds + clearedAt（重复无操作）
///   - chapterCompleted：该章所有 stage 是否都已通关
///
/// 与 [BattleResolutionService] 解耦：Phase 3 由 UI（StageEntryFlow）在
/// onVictory 回调里显式调 recordVictory；Phase 4 再考虑接进战斗结算 hook。
class MainlineProgressService {
  const MainlineProgressService({required this.isar});

  final Isar isar;

  /// 拿不到对应 saveDataId 的行就建一行（默认 currentChapterIndex=1，
  /// clearedStageIds/clearedAt 空）。
  Future<MainlineProgress> getOrCreate({
    required int saveDataId,
  }) async {
    final existing = await isar.mainlineProgress
        .filter()
        .saveDataIdEqualTo(saveDataId)
        .findFirst();
    if (existing != null) return existing;

    final fresh = MainlineProgress()
      ..saveDataId = saveDataId
      ..currentChapterIndex = 1
      ..clearedStageIds = []
      ..clearedAt = [];
    await isar.writeTxn(() => isar.mainlineProgress.put(fresh));
    return fresh;
  }

  /// 该章所有 stage（含已通 + 可挑 + 锁三态），按 prevStageId 链推顺序。
  ///
  /// 解锁规则：
  ///   - prevStageId == null → 章节首关，无条件 available（除非已通 → cleared）
  ///   - prevStageId 已在 clearedStageIds → available（除非自己已通 → cleared）
  ///   - 否则 → locked
  static List<StageEntry> availableStages({
    required MainlineProgress progress,
    required int chapterIndex,
  }) {
    final all = GameRepository.instance.stageDefs.values
        .where((s) => s.chapterIndex == chapterIndex)
        .toList();
    // 按 prev 链排序：首关在前。简单 BFS：先把无 prev 的放头，再按 prev 已排进的顺序加后续。
    final ordered = <StageDef>[];
    final remaining = List<StageDef>.of(all);
    // 第一波：所有 prevStageId == null
    final heads = remaining.where((s) => s.prevStageId == null).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    ordered.addAll(heads);
    remaining.removeWhere(heads.contains);
    // 后续：每轮把 prev 已在 ordered 的关加进来，直到无变化
    while (remaining.isNotEmpty) {
      final orderedIds = ordered.map((s) => s.id).toSet();
      final next = remaining
          .where((s) => orderedIds.contains(s.prevStageId))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      if (next.isEmpty) break; // 防御：理论上 _enforceRedLines 已拦截链断
      ordered.addAll(next);
      remaining.removeWhere(next.contains);
    }

    final cleared = progress.clearedStageIds.toSet();
    return ordered.map((s) {
      final selfCleared = cleared.contains(s.id);
      if (selfCleared) return (def: s, status: StageStatus.cleared);
      final prev = s.prevStageId;
      final unlocked = prev == null || cleared.contains(prev);
      return (
        def: s,
        status: unlocked ? StageStatus.available : StageStatus.locked,
      );
    }).toList(growable: false);
  }

  /// 首通 append；重复通关无副作用（保持首通时间）。
  ///
  /// **注意**：调用方负责保证 stageId 真实存在（GameRepository.getStage）；
  /// 本服务不做 stageId 合法性校验，避免每次写都全表查。
  ///
  /// P1 #42 Phase 2 §10 P1.x:可选注入 [tutorialService],在同 writeTxn 内
  /// 原子推进 [SaveData.tutorialStep](Ch1 stage_01_0X → step X)。
  /// 测试 / debug seed 路径默认 null,不触发引导递增。
  Future<void> recordVictory({
    required String stageId,
    required DateTime now,
    TutorialService? tutorialService,
  }) async {
    await isar.writeTxn(() async {
      final progress = await isar.mainlineProgress
          .filter()
          .saveDataIdEqualTo(IsarSetup.currentSlotId)
          .findFirst();
      if (progress == null) {
        throw StateError(
          'MainlineProgress 未初始化：getOrCreate 未在 recordVictory 前调用',
        );
      }
      if (progress.clearedStageIds.contains(stageId)) {
        return; // 幂等：重复通关不二次 append
      }
      progress.clearedStageIds = [...progress.clearedStageIds, stageId];
      progress.clearedAt = [...progress.clearedAt, now];
      await isar.mainlineProgress.put(progress);
      await tutorialService?.advanceForStageCleared(stageId);
    });
  }

  /// 该章所有 stage 都在 cleared 集 → true。空章（理论上不存在）→ false。
  static bool chapterCompleted({
    required MainlineProgress progress,
    required int chapterIndex,
  }) {
    final inChapter = GameRepository.instance.stageDefs.values
        .where((s) => s.chapterIndex == chapterIndex)
        .map((s) => s.id)
        .toSet();
    if (inChapter.isEmpty) return false;
    return inChapter.every(progress.clearedStageIds.contains);
  }
}
