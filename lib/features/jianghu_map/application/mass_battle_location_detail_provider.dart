import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/defs/mass_battle_def.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../../shared/battle_shared/current_leader_resolver.dart';
import '../../loot_preview/domain/drop_rumor.dart';
import '../../mainline/application/mainline_providers.dart';
import '../../mass_battle/application/mass_battle_service.dart';
import '../domain/mass_battle_location_detail.dart';

/// 为地点详情与地图入口校验守城解锁图，拒绝多根、汇合、环与截断配置。
List<String> validatedMassBattleLocationStageIds(MassBattleDef config) {
  final routeIds = config.stageFormations.keys
      .where((id) => id.startsWith('stage_mass_battle_'))
      .toSet();
  if (routeIds.isEmpty || config.unlockTriggers.length != routeIds.length) {
    throw StateError('Mass battle location detail has invalid route graph');
  }

  final externalRoots = config.unlockTriggers.entries
      .where((entry) => !routeIds.contains(entry.key))
      .toList(growable: false);
  final values = config.unlockTriggers.values.toList(growable: false);
  if (externalRoots.length != 1 ||
      values.any((id) => !routeIds.contains(id)) ||
      values.toSet().length != values.length ||
      values.toSet().length != routeIds.length) {
    throw StateError('Mass battle location detail has invalid route graph');
  }

  final ordered = <String>[];
  final visited = <String>{};
  String? current = externalRoots.single.value;
  while (current != null && ordered.length <= routeIds.length) {
    if (!routeIds.contains(current) || !visited.add(current)) {
      throw StateError('Mass battle location detail has cyclic route graph');
    }
    ordered.add(current);
    current = config.unlockTriggers[current];
  }
  if (current != null ||
      ordered.length != routeIds.length ||
      !visited.containsAll(routeIds)) {
    throw StateError('Mass battle location detail has truncated route graph');
  }
  return List.unmodifiable(ordered);
}

final massBattleLocationDetailProvider =
    FutureProvider<MassBattleLocationDetail>((ref) async {
      final isar = ref.watch(isarProvider);
      if (isar == null) {
        throw StateError(
          'Mass battle location detail unavailable: Isar not initialized',
        );
      }

      final progress = await ref.watch(mainlineProgressProvider.future);
      final repository = GameRepository.instance;
      final config = repository.numbers.massBattle;
      final stageIds = validatedMassBattleLocationStageIds(config);

      final stages = <StageDef>[];
      for (final stageId in stageIds) {
        final stage = repository.getStage(stageId);
        final waveCount = stage.massBattleWaveCount;
        final enemyCounts = stage.massBattleEnemyCounts;
        if (stage.stageType != StageType.massBattle ||
            waveCount == null ||
            waveCount <= 0 ||
            enemyCounts == null ||
            enemyCounts.length != waveCount ||
            enemyCounts.any((count) => count <= 0) ||
            stage.enemyTeam.isEmpty) {
          throw StateError(
            'Mass battle location detail has invalid stage config: $stageId',
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
        throw StateError('Mass battle location detail is not unlocked');
      }

      var clearedRoutes = 0;
      var reachedUncleared = false;
      for (final stageId in stageIds) {
        final isCleared = cleared.contains(stageId);
        if (isCleared && reachedUncleared) {
          throw StateError(
            'Mass battle location detail has non-contiguous progress: $stageId',
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
        final status = MassBattleService.statusOf(
          stageId: candidate.id,
          config: config,
          clearedStageIds: cleared,
        );
        if (status != MassBattleStageStatus.available) {
          throw StateError(
            'Mass battle location detail has no available next stage: '
            '${candidate.id}',
          );
        }
        nextStage = candidate;
      }

      final save = await isar.saveDatas.get(0);
      final leaderId = await CurrentLeaderResolver.resolve(
        save: save,
        characterExists: (id) async => await isar.characters.get(id) != null,
      );
      final leader = await isar.characters.get(leaderId);
      if (leader == null) {
        throw StateError(
          'Mass battle location detail leader disappeared: $leaderId',
        );
      }

      final enemyCounts = nextStage?.massBattleEnemyCounts;
      return MassBattleLocationDetail(
        clearedRoutes: clearedRoutes,
        totalRoutes: stages.length,
        nextStageId: nextStage?.id,
        nextStageName: nextStage?.name,
        recommendedRealm: nextStage?.requiredRealm,
        formation: nextStage == null
            ? null
            : config.stageFormations[nextStage.id],
        waveCount: nextStage?.massBattleWaveCount,
        enemyTotal: enemyCounts?.fold<int>(0, (sum, count) => sum + count),
        enemies: List.unmodifiable([
          for (final enemy in nextStage?.enemyTeam ?? const <EnemyDef>[])
            MassBattleLocationEnemySummary(
              name: enemy.name,
              school: enemy.school,
            ),
        ]),
        rewardRumor: nextStage == null
            ? null
            : DropRumorTable.fromDropTable(
                nextStage.dropTable,
                gating: FirstClearGating.wholeChannel,
              ),
        baseExpReward: nextStage?.baseExpReward,
        participantId: leaderId,
        participantName: leader.name,
      );
    }, dependencies: [isarProvider, mainlineProgressProvider]);
