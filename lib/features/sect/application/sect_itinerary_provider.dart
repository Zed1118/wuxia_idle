import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/isar_provider.dart';
import '../../../shared/battle_shared/current_leader_resolver.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../../boss_gauntlet/application/gauntlet_providers.dart';
import '../../expedition/application/expedition_providers.dart';
import '../domain/sect_itinerary_summary.dart';

final sectItineraryProvider = FutureProvider<SectItinerarySummary>((ref) async {
  final isar = ref.watch(isarProvider);
  if (isar == null) {
    throw StateError('Sect itinerary unavailable: Isar is not initialized');
  }

  final save = await isar.saveDatas.get(0);
  final leaderId = await CurrentLeaderResolver.resolve(
    save: save,
    characterExists: (id) async => await isar.characters.get(id) != null,
  );
  final leader = await isar.characters.get(leaderId);
  if (leader == null) {
    throw StateError('Sect itinerary leader disappeared: $leaderId');
  }

  final occupancy = await CharacterOccupancyService(isar).snapshot();
  final occupiedMembers = <SectItineraryOccupiedMember>[];
  final seenCharacterIds = <int>{};
  for (final entry in occupancy.entries) {
    for (final characterId in entry.characterIds) {
      if (!seenCharacterIds.add(characterId)) {
        throw StateError(
          'Sect itinerary has duplicate activity occupancy: $characterId',
        );
      }
      final character = await isar.characters.get(characterId);
      if (character == null) {
        throw StateError(
          'Sect itinerary occupancy references missing character: '
          '$characterId',
        );
      }
      occupiedMembers.add(
        SectItineraryOccupiedMember(
          characterId: characterId,
          name: character.name,
          activity: entry.kind,
        ),
      );
    }
  }
  occupiedMembers.sort((a, b) {
    final byActivity = a.activity.index.compareTo(b.activity.index);
    return byActivity != 0
        ? byActivity
        : a.characterId.compareTo(b.characterId);
  });

  final expedition = await ref.watch(activeExpeditionProvider.future);
  final gauntlet = await ref.watch(activeGauntletProvider.future);
  return SectItinerarySummary(
    leaderId: leaderId,
    leaderName: leader.name,
    occupiedMembers: List.unmodifiable(occupiedMembers),
    expeditionDepth: expedition?.currentNode,
    expeditionDefeated: expedition?.defeated ?? false,
    gauntletStage: gauntlet?.currentStage,
    gauntletPhase: gauntlet?.sessionPhase,
  );
});
