import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/game_repository.dart';
import '../data/isar_setup.dart';
import '../features/encounter/domain/encounter_progress.dart';
import '../features/dispel/application/dispel_service.dart';
import '../features/encounter/application/encounter_service.dart';
import '../features/equipment/application/enhancement_service.dart';
import '../features/equipment/application/forging_service.dart';
import '../features/mainline/application/mainline_progress_service.dart';
import '../services/phase2_seed_service.dart';
import '../features/seclusion/application/seclusion_service.dart';
import '../features/battle/application/stage_battle_setup.dart';
import '../features/tower/application/tower_progress_service.dart';

part 'isar_provider.g.dart';

/// Isar 实例 provider（Phase 5 W6-S2 引入，nullable propagation 主干）。
///
/// 生产路径：`main()` 中 [IsarSetup.init] 跑完后非 null,直接读用。
/// 测试路径：widget test 不 init Isar 时返回 null,由 service provider
/// 进一步传递 nullable —— 替代旧的 widget 端 `Isar.getInstance` guard。
///
/// 实现：走 [IsarSetup.instanceOrNull]（探测式 getter,未 init 不抛）。
@riverpod
Isar? isar(Ref ref) => IsarSetup.instanceOrNull;

/// GameRepository 单例 provider。生产代码 main() 中 [GameRepository.loadAllDefs]
/// 完成后即可读。widget test setUpAll 通常预先 load。
///
/// 不 nullable：GameRepository 是项目启动必备,即使测试也通过 setUpAll
/// 加载,不存在"不 load 跑测试"的合理场景。
@riverpod
GameRepository gameRepository(Ref ref) => GameRepository.instance;

// =========================================================================
// Service providers（Phase 5 W6-S2 引入,nullable propagation 链）
//
// 每个 service 持有 Isar 实例,通过 isarProvider 派生。isar 为 null 时
// service 也为 null —— widget 端短路返回,替代旧的散点 Isar.getInstance guard。
// =========================================================================

/// [EnhancementService] provider。Isar 未 init 时为 null,widget 端 `_persist`
/// 用 `service == null` 短路（替代旧的 `Isar.getInstance(_isarInstanceName)` guard）。
@riverpod
EnhancementService? enhancementService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null ? null : EnhancementService(isar: isarInstance);
}

/// [ForgingService] provider。同 [enhancementServiceProvider] 模式。
@riverpod
ForgingService? forgingService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null ? null : ForgingService(isar: isarInstance);
}

/// [DispelService] provider。同上模式。
@riverpod
DispelService? dispelService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null ? null : DispelService(isar: isarInstance);
}

/// [Phase2SeedService] provider。
@riverpod
Phase2SeedService? phase2SeedService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null ? null : Phase2SeedService(isar: isarInstance);
}

/// [MainlineProgressService] provider。
@riverpod
MainlineProgressService? mainlineProgressService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null
      ? null
      : MainlineProgressService(isar: isarInstance);
}

/// [TowerProgressService] provider。
@riverpod
TowerProgressService? towerProgressService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null
      ? null
      : TowerProgressService(isar: isarInstance);
}

/// [SeclusionService] provider。
///
/// C-W14-2:同时注入 [EncounterService],让 [SeclusionService.completeRetreat]
/// 在 actualHours 完成后能喂 biome/weather 累计分钟给奇遇系统。
@riverpod
SeclusionService? seclusionService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  if (isarInstance == null) return null;
  return SeclusionService(
    isar: isarInstance,
    encounterService: EncounterService(isar: isarInstance),
  );
}

/// [StageBattleSetup] provider。
@riverpod
StageBattleSetup? stageBattleSetup(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null ? null : StageBattleSetup(isar: isarInstance);
}

/// [EncounterService] provider(Phase 4 W14-1)。
@riverpod
EncounterService? encounterService(Ref ref) {
  final isarInstance = ref.watch(isarProvider);
  return isarInstance == null ? null : EncounterService(isar: isarInstance);
}

/// 当前存档 [EncounterProgress] 行(C-W14-3-A)。
///
/// UI 装备奇遇 skill 面板用,装/卸后 caller 调
/// `ref.invalidate(currentEncounterProgressProvider)` 刷新。返回 null 表示
/// Isar 未 init 或 getOrCreate 未跑过(应由 caller 兜底文案,不抛错)。
@riverpod
Future<EncounterProgress?> currentEncounterProgress(Ref ref) async {
  final isarInstance = ref.watch(isarProvider);
  if (isarInstance == null) return null;
  return isarInstance.encounterProgress
      .filter()
      .saveDataIdEqualTo(IsarSetup.currentSlotId)
      .findFirst();
}
