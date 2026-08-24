import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/defs/stage_def.dart' show EnemyDef;
import '../../../data/game_repository.dart';
import '../../../data/isar_provider.dart';
import '../../../shared/battle_shared/current_leader_resolver.dart';
import '../../loot_preview/domain/drop_rumor.dart';
import '../../tower/application/tower_providers.dart';
import '../domain/tower_location_detail.dart';

final towerLocationDetailProvider = FutureProvider<TowerLocationDetail>((
  ref,
) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) {
    throw StateError('Tower location detail unavailable: Isar not initialized');
  }

  final progress = await ref.watch(towerProgressProvider.future);
  final repository = GameRepository.instance;
  final totalFloors = repository.towerMaxFloor;
  if (totalFloors <= 0 ||
      progress.highestClearedFloor < 0 ||
      progress.highestClearedFloor > totalFloors) {
    throw StateError(
      'Tower location detail has invalid progress/config: '
      '${progress.highestClearedFloor}/$totalFloors',
    );
  }

  final save = await isar.saveDatas.get(0);
  final leaderId = await CurrentLeaderResolver.resolve(
    save: save,
    characterExists: (id) async => await isar.characters.get(id) != null,
  );
  final leader = await isar.characters.get(leaderId);
  if (leader == null) {
    throw StateError('Tower location detail leader disappeared: $leaderId');
  }

  final complete = progress.highestClearedFloor == totalFloors;
  final nextFloor = complete
      ? null
      : repository.getTowerFloor(progress.highestClearedFloor + 1);
  return TowerLocationDetail(
    highestClearedFloor: progress.highestClearedFloor,
    totalFloors: totalFloors,
    nextFloorIndex: nextFloor?.floorIndex,
    recommendedRealm: nextFloor?.requiredRealm,
    enemies: List.unmodifiable([
      for (final enemy in nextFloor?.enemyTeam ?? const <EnemyDef>[])
        TowerLocationEnemySummary(name: enemy.name, school: enemy.school),
    ]),
    rewardRumor: nextFloor == null
        ? null
        : DropRumorTable.fromDropTable(
            nextFloor.dropTable,
            gating: FirstClearGating.wholeChannel,
          ),
    baseExpReward: nextFloor?.baseExpReward,
    participantId: leaderId,
    participantName: leader.name,
  );
}, dependencies: [isarProvider, towerProgressProvider]);
