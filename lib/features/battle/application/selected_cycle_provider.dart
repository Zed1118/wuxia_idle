import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../mainline/application/mainline_progress_service.dart';
import '../../mainline/domain/mainline_progress.dart';

part 'selected_cycle_provider.g.dart';

/// 章级「当前选定挑战周目」UI 状态(战斗交互重做 Phase 2 周目按章)。
///
/// key = chapterKey(主线 `ch{N}` / 副本 `stageType.name`)。`null` = 玩家未显式
/// 选择,caller 用 [resolveTargetCycle] 兜底(已通章→回放最高周目;未通章→cycle 1)。
/// 玩家在章头点「挑战第(N+1)周目」时设为 N+1,点「回放第N周目」设回 N。
///
/// 纯 UI 状态,不落盘——切屏重进回默认。周目解锁的真相源仍是
/// [MainlineProgress.clearedChapterCycleKeys](service 层)。
@riverpod
class SelectedChallengeCycle extends _$SelectedChallengeCycle {
  @override
  int? build(String chapterKey) => null;

  void select(int cycle) => state = cycle;
}

/// 解析某章实际进入战斗用的周目:玩家显式选择优先,否则已通章回放最高周目,
/// 未通章(highest==0)用 cycle 1(首通)。
int resolveTargetCycle(
  int? selected,
  MainlineProgress progress,
  String chapterKey,
) {
  if (selected != null) return selected;
  final hi = MainlineProgressService.highestClearedCycleForChapter(
    progress,
    chapterKey,
  );
  return hi == 0 ? 1 : hi;
}
