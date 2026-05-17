import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../domain/tower_progress.dart';
import 'leaderboard_sync_service.dart';
import 'tower_progress_service.dart';

part 'tower_providers.g.dart';

/// 当前存档的爬塔进度（Phase 3 T42）。
///
/// recordClear / recordDefeat 后调用 `ref.invalidate(towerProgressProvider)`
/// 触发刷新，[towerFloorListProvider] 自动级联。
@Riverpod(dependencies: [])
Future<TowerProgress> towerProgress(Ref ref) async {
  return TowerProgressService(isar: IsarSetup.instance).getOrCreate(
    saveDataId: IsarSetup.currentSlotId,
  );
}

/// 30 层列表含三态 status（Phase 3 T42）。
///
/// 依赖 [towerProgressProvider]，进度刷新后自动级联。
@Riverpod(dependencies: [towerProgress])
Future<List<TowerFloorEntry>> towerFloorList(Ref ref) async {
  final progress = await ref.watch(towerProgressProvider.future);
  return TowerProgressService.floorList(
    progress: progress,
    allFloors: GameRepository.instance.towerFloors,
  );
}

/// 排行榜同步服务(P0.2 #40 Phase 3,方案 D placeholder)。
///
/// Demo 阶段默认注入 [NoopLeaderboardSync](0 backend / 0 network call)。
/// 未来升 Pro plan 接 Supabase 时,替换返回为 SupabaseLeaderboardSync 即可,
/// victory hook 0 改动。
@Riverpod(dependencies: [])
LeaderboardSyncService leaderboardSync(Ref ref) {
  return const NoopLeaderboardSync();
}
