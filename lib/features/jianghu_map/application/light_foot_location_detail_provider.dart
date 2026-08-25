import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/defs/light_foot_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../light_foot/application/light_foot_participant_service.dart';
import '../../light_foot/application/light_foot_service.dart';
import '../../loot_preview/domain/drop_rumor.dart';
import '../../mainline/application/mainline_providers.dart';
import '../domain/light_foot_location_detail.dart';

/// 为地点详情校验轻功解锁图，避免不合法配置在通用链遍历中循环。
List<String> validatedLightFootLocationStageIds(LightFootDef config) {
  final routeIds = config.stageTerrain.keys
      .where((id) => id.startsWith('stage_light_foot_'))
      .toSet();
  if (routeIds.isEmpty || config.unlockTriggers.length != routeIds.length) {
    throw StateError('Light foot location detail has invalid route graph');
  }

  final externalRoots = config.unlockTriggers.entries
      .where((entry) => !routeIds.contains(entry.key))
      .toList(growable: false);
  final values = config.unlockTriggers.values.toList(growable: false);
  if (externalRoots.length != 1 ||
      values.any((id) => !routeIds.contains(id)) ||
      values.toSet().length != values.length ||
      values.toSet().length != routeIds.length) {
    throw StateError('Light foot location detail has invalid route graph');
  }

  final ordered = <String>[];
  final visited = <String>{};
  String? current = externalRoots.single.value;
  while (current != null && ordered.length <= routeIds.length) {
    if (!routeIds.contains(current) || !visited.add(current)) {
      throw StateError('Light foot location detail has cyclic route graph');
    }
    ordered.add(current);
    current = config.unlockTriggers[current];
  }
  if (current != null ||
      ordered.length != routeIds.length ||
      !visited.containsAll(routeIds)) {
    throw StateError('Light foot location detail has truncated route graph');
  }
  return List.unmodifiable(ordered);
}

final lightFootLocationDetailProvider = FutureProvider<LightFootLocationDetail>(
  (ref) async {
    final isar = ref.watch(isarProvider);
    if (isar == null) {
      throw StateError(
        'Light foot location detail unavailable: Isar not initialized',
      );
    }

    final progress = await ref.watch(mainlineProgressProvider.future);
    final repository = GameRepository.instance;
    final config = repository.numbers.lightFoot;
    final stageIds = validatedLightFootLocationStageIds(config);

    final stages = <StageDef>[];
    for (final stageId in stageIds) {
      final stage = repository.getStage(stageId);
      if (stage.stageType != StageType.lightFoot ||
          stage.terrainBiome == null) {
        throw StateError(
          'Light foot location detail has invalid stage config: $stageId',
        );
      }
      stages.add(stage);
    }

    final cleared = progress.clearedStageIds.toSet();
    final firstPrerequisites = config.unlockTriggers.entries
        .where((entry) => entry.value == stageIds.first)
        .map((entry) => entry.key)
        .toList(growable: false);
    if (firstPrerequisites.length != 1 ||
        !cleared.contains(firstPrerequisites.single)) {
      throw StateError('Light foot location detail is not unlocked');
    }

    var clearedRoutes = 0;
    var reachedUncleared = false;
    for (final stageId in stageIds) {
      final isCleared = cleared.contains(stageId);
      if (isCleared && reachedUncleared) {
        throw StateError(
          'Light foot location detail has non-contiguous progress: $stageId',
        );
      }
      if (isCleared) {
        clearedRoutes += 1;
      } else {
        reachedUncleared = true;
      }
    }

    StageDef? nextStage;
    if (clearedRoutes < stages.length) {
      final candidate = stages[clearedRoutes];
      final status = LightFootService.statusOf(
        stageId: candidate.id,
        config: config,
        clearedStageIds: cleared,
      );
      if (status != LightFootStageStatus.available) {
        throw StateError(
          'Light foot location detail has no available next route: '
          '${candidate.id}',
        );
      }
      nextStage = candidate;
    }

    final participantCandidates = await loadLightFootParticipantCandidates(
      isar: isar,
    );

    return LightFootLocationDetail(
      clearedRoutes: clearedRoutes,
      totalRoutes: stages.length,
      nextStageId: nextStage?.id,
      nextStageName: nextStage?.name,
      recommendedRealm: nextStage?.requiredRealm,
      terrainBiome: nextStage?.terrainBiome,
      enemies: List.unmodifiable([
        for (final enemy in nextStage?.enemyTeam ?? const <EnemyDef>[])
          LightFootLocationEnemySummary(name: enemy.name, school: enemy.school),
      ]),
      rewardRumor: nextStage == null
          ? null
          : DropRumorTable.fromDropTable(
              nextStage.dropTable,
              gating: FirstClearGating.wholeChannel,
            ),
      baseExpReward: nextStage?.baseExpReward,
      eligibleParticipantCount: participantCandidates
          .where((candidate) => candidate.selectable)
          .length,
    );
  },
  dependencies: [isarProvider, mainlineProgressProvider],
);
