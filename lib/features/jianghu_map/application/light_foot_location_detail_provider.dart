import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../../shared/battle_shared/current_leader_resolver.dart';
import '../../light_foot/application/light_foot_service.dart';
import '../../loot_preview/domain/drop_rumor.dart';
import '../../mainline/application/mainline_providers.dart';
import '../domain/light_foot_location_detail.dart';

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
    final stageIds = LightFootService.orderedStageIds(config);
    if (stageIds.isEmpty || stageIds.toSet().length != stageIds.length) {
      throw StateError('Light foot location detail has invalid route chain');
    }

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

    final save = await isar.saveDatas.get(0);
    final leaderId = await CurrentLeaderResolver.resolve(
      save: save,
      characterExists: (id) async => await isar.characters.get(id) != null,
    );
    final leader = await isar.characters.get(leaderId);
    if (leader == null) {
      throw StateError(
        'Light foot location detail leader disappeared: $leaderId',
      );
    }

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
      participantId: leaderId,
      participantName: leader.name,
    );
  },
  dependencies: [isarProvider, mainlineProgressProvider],
);
