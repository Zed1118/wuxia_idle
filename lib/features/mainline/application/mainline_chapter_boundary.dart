import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';

/// 主线一章完成后的唯一跨章事实。
final class MainlineChapterBoundary {
  const MainlineChapterBoundary({
    required this.completedChapterIndex,
    required this.completedStageId,
    required this.nextChapterIndex,
    required this.nextChapterFirstStage,
  });

  final int completedChapterIndex;
  final String completedStageId;
  final int? nextChapterIndex;
  final StageDef? nextChapterFirstStage;

  bool get isFinalChapter => nextChapterIndex == null;
}

/// 只在真实章末返回边界；章内关卡返回 null。
///
/// 下一章必须章号连续且恰有一个无前驱的主线首关，否则 fail closed。
MainlineChapterBoundary? resolveMainlineChapterBoundary({
  required GameRepository repository,
  required StageDef completedStage,
}) {
  final chapterIndex = completedStage.chapterIndex;
  if (completedStage.stageType != StageType.mainline || chapterIndex == null) {
    return null;
  }
  final mainlineStages = repository.stageDefs.values
      .where((stage) => stage.stageType == StageType.mainline)
      .toList(growable: false);
  final sameChapterSuccessors = mainlineStages
      .where(
        (stage) =>
            stage.chapterIndex == chapterIndex &&
            stage.prevStageId == completedStage.id,
      )
      .toList(growable: false);
  if (sameChapterSuccessors.length > 1) {
    throw StateError('Mainline stage has multiple same-chapter successors');
  }
  if (sameChapterSuccessors.isNotEmpty) return null;

  final laterChapters =
      mainlineStages
          .map((stage) => stage.chapterIndex)
          .whereType<int>()
          .where((candidate) => candidate > chapterIndex)
          .toSet()
          .toList(growable: false)
        ..sort();
  if (laterChapters.isEmpty) {
    return MainlineChapterBoundary(
      completedChapterIndex: chapterIndex,
      completedStageId: completedStage.id,
      nextChapterIndex: null,
      nextChapterFirstStage: null,
    );
  }
  final nextChapterIndex = laterChapters.first;
  if (nextChapterIndex != chapterIndex + 1) {
    throw StateError('Mainline chapters are not contiguous');
  }
  final firstStages = mainlineStages
      .where(
        (stage) =>
            stage.chapterIndex == nextChapterIndex && stage.prevStageId == null,
      )
      .toList(growable: false);
  if (firstStages.length != 1) {
    throw StateError('Next mainline chapter must have exactly one first stage');
  }
  return MainlineChapterBoundary(
    completedChapterIndex: chapterIndex,
    completedStageId: completedStage.id,
    nextChapterIndex: nextChapterIndex,
    nextChapterFirstStage: firstStages.single,
  );
}
