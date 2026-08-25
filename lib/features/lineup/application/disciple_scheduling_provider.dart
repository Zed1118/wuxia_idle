import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/isar_provider.dart';
import '../../../shared/battle_shared/current_leader_resolver.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../../activity/domain/activity_occupancy.dart';
import '../domain/disciple_scheduling_summary.dart';

/// 二阶段 U08 门人调度当前态。
///
/// 只读当前掌门、当代门人与统一活动占用；不读取旧三席顺序作为战斗阵容，
/// 更不写 `SaveData.activeCharacterIds` / `Character.isActive`。
final discipleSchedulingProvider = FutureProvider<DiscipleSchedulingSummary>((
  ref,
) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) {
    throw StateError('Disciple scheduling unavailable: Isar not initialized');
  }

  final save = await isar.saveDatas.get(0);
  final leaderId = await CurrentLeaderResolver.resolve(
    save: save,
    characterExists: (id) async => await isar.characters.get(id) != null,
  );
  final allCharacters = await isar.characters.where().findAll();
  final byId = {for (final character in allCharacters) character.id: character};
  final leader = byId[leaderId];
  if (leader == null || !leader.isFounder) {
    throw StateError('Disciple scheduling leader is not a current founder');
  }

  final memberIds = <int>{leaderId};
  void includeReferencedIds(
    Iterable<int> ids,
    String source, {
    required bool allowLeader,
    required bool ignoreDifferentMaster,
  }) {
    for (final id in ids) {
      final character = byId[id];
      if (character == null) {
        throw StateError(
          'Disciple scheduling $source references missing character: $id',
        );
      }
      if (id == leaderId) {
        if (!allowLeader) {
          throw StateError(
            'Disciple scheduling $source references the current leader: $id',
          );
        }
        continue;
      }
      if (character.isFounder) {
        throw StateError(
          'Disciple scheduling $source references another founder: $id',
        );
      }
      // 多代存档中，仍残留于兼容列表但已明确归属旧掌门的角色不属于当代。
      if (character.masterId != null && character.masterId != leaderId) {
        if (ignoreDifferentMaster) continue;
        throw StateError(
          'Disciple scheduling $source references another generation: $id',
        );
      }
      memberIds.add(id);
    }
  }

  includeReferencedIds(
    leader.discipleIds,
    'leader.discipleIds',
    allowLeader: false,
    ignoreDifferentMaster: false,
  );
  includeReferencedIds(
    save?.activeCharacterIds ?? const <int>[],
    'activeCharacterIds',
    allowLeader: true,
    ignoreDifferentMaster: true,
  );
  includeReferencedIds(
    save?.recruitedDiscipleIds ?? const <int>[],
    'recruitedDiscipleIds',
    allowLeader: false,
    ignoreDifferentMaster: true,
  );
  for (final character in allCharacters) {
    if (!character.isFounder && character.masterId == leaderId) {
      memberIds.add(character.id);
    }
  }

  final occupancy = await CharacterOccupancyService(isar).snapshot();
  final activityByCharacterId = <int, ActivityKind>{};
  for (final entry in occupancy.entries) {
    for (final characterId in entry.characterIds) {
      if (!byId.containsKey(characterId)) {
        throw StateError(
          'Disciple scheduling occupancy references missing character: '
          '$characterId',
        );
      }
      if (activityByCharacterId.containsKey(characterId)) {
        throw StateError(
          'Disciple scheduling duplicate activity occupancy: $characterId',
        );
      }
      activityByCharacterId[characterId] = entry.kind;
    }
  }

  final characters =
      memberIds.map((id) => byId[id]).whereType<Character>().toList()
        ..sort((a, b) {
          if (a.id == leaderId) return -1;
          if (b.id == leaderId) return 1;
          return a.id.compareTo(b.id);
        });
  if (characters.isEmpty || characters.first.id != leaderId) {
    throw StateError('Disciple scheduling could not resolve current leader');
  }

  return DiscipleSchedulingSummary(
    leaderId: leaderId,
    members: List.unmodifiable([
      for (final character in characters)
        DiscipleSchedulingMember(
          characterId: character.id,
          name: character.name,
          realmTier: character.realmTier,
          realmLayer: character.realmLayer,
          isLeader: character.id == leaderId,
          isAlive: character.isAlive,
          activity: activityByCharacterId[character.id],
          portraitPath: character.portraitPath,
        ),
    ]),
  );
});
