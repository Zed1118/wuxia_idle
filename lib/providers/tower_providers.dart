import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/game_repository.dart';
import '../data/isar_setup.dart';
import '../data/models/tower_progress.dart';
import '../services/tower_progress_service.dart';

part 'tower_providers.g.dart';

/// 当前存档的爬塔进度（Phase 3 T42）。
///
/// recordClear / recordDefeat 后调用 `ref.invalidate(towerProgressProvider)`
/// 触发刷新，[towerFloorListProvider] 自动级联。
@riverpod
Future<TowerProgress> towerProgress(TowerProgressRef ref) async {
  return TowerProgressService.getOrCreate(
    saveDataId: IsarSetup.currentSlotId,
  );
}

/// 30 层列表含三态 status（Phase 3 T42）。
///
/// 依赖 [towerProgressProvider]，进度刷新后自动级联。
@riverpod
Future<List<TowerFloorEntry>> towerFloorList(TowerFloorListRef ref) async {
  final progress = await ref.watch(towerProgressProvider.future);
  return TowerProgressService.floorList(
    progress: progress,
    allFloors: GameRepository.instance.towerFloors,
  );
}
