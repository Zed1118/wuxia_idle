import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/isar_setup.dart';
import '../data/models/mainline_progress.dart';
import '../services/mainline_progress_service.dart';

part 'mainline_providers.g.dart';

/// 当前存档的主线进度（Phase 3 T34/T35）。
///
/// Phase 3 仅一个存档，saveDataId = [IsarSetup.currentSlotId]（默认 1）。
/// recordVictory 后调用 `ref.invalidate(mainlineProgressProvider)` 触发刷新。
@riverpod
Future<MainlineProgress> mainlineProgress(Ref ref) async {
  return MainlineProgressService(isar: IsarSetup.instance).getOrCreate(
    saveDataId: IsarSetup.currentSlotId,
  );
}

/// 指定章节的关卡列表（含三态 status）。
///
/// 依赖 [mainlineProgressProvider]，前者刷新自动级联。
@riverpod
Future<List<StageEntry>> chapterStages(
  Ref ref,
  int chapterIndex,
) async {
  final progress = await ref.watch(mainlineProgressProvider.future);
  return MainlineProgressService.availableStages(
    progress: progress,
    chapterIndex: chapterIndex,
  );
}

/// 指定章节是否全通（chapter list 上 ✓ 标识用）。
@riverpod
Future<bool> chapterCompleted(
  Ref ref,
  int chapterIndex,
) async {
  final progress = await ref.watch(mainlineProgressProvider.future);
  return MainlineProgressService.chapterCompleted(
    progress: progress,
    chapterIndex: chapterIndex,
  );
}
