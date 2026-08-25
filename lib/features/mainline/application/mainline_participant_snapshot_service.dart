import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/technique.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/current_leader_resolver.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_assembler.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import '../domain/mainline_participation_policy.dart';

String mainlineLoadoutPlanId({
  required String stageId,
  required int characterId,
}) => 'mainline:$stageId:character:$characterId';

final class ResolvedMainlineParticipantSnapshot {
  const ResolvedMainlineParticipantSnapshot({
    required this.request,
    required this.selection,
    required this.snapshot,
  });

  final ActivityParticipationRequest request;
  final MainlineParticipantSelection selection;
  final CombatantSnapshot snapshot;
}

/// Resolves every mainline mode through the frozen participant policy and the
/// existing exact production snapshot assembler.
///
/// This service owns no persistence or battle rules. It only validates the
/// explicit request against current save/occupancy/loadout facts and fails
/// closed before the existing live or headless runner starts.
final class MainlineParticipantSnapshotService {
  const MainlineParticipantSnapshotService(this._isar);

  final Isar _isar;

  Future<ResolvedMainlineParticipantSnapshot> resolve(
    ActivityParticipationRequest request,
  ) async {
    _validateMode(request);
    final save = await _isar.saveDatas.get(0);
    late final int currentLeaderId;
    try {
      currentLeaderId = await CurrentLeaderResolver.resolve(
        save: save,
        characterExists: (id) async => await _isar.characters.get(id) != null,
      );
    } on StateError {
      throw const MainlineParticipationRefusedError(
        'Current leader pointer is invalid for mainline participation',
      );
    }

    final requestedEligible = await _isBattleEligible(
      save: save,
      characterId: request.characterId,
    );
    final selection = MainlineParticipationPolicy.resolveParticipant(
      request: request,
      currentLeaderId: currentLeaderId,
      requestedIdleEligible: requestedEligible,
    );
    if (request.characterId != selection.participantId) {
      throw const MainlineParticipationRefusedError(
        'Mainline request character does not match the policy participant',
      );
    }
    final expectedLoadoutPlanId = mainlineLoadoutPlanId(
      stageId: request.contentId,
      characterId: selection.participantId,
    );
    if (request.loadoutPlanId != expectedLoadoutPlanId) {
      throw const MainlineParticipationRefusedError(
        'Mainline request loadout identity is stale or mismatched',
      );
    }
    if (!await _isBattleEligible(
      save: save,
      characterId: selection.participantId,
    )) {
      throw const MainlineParticipationRefusedError(
        'Selected mainline participant is not battle eligible',
      );
    }

    try {
      final roster = await PlayerCombatantSnapshotAssembler(
        isar: _isar,
      ).loadExactRoster([selection.participantId]);
      if (roster.length != 1 ||
          roster.single.characterId != selection.participantId) {
        throw StateError('mainline exact participant mismatch');
      }
      return ResolvedMainlineParticipantSnapshot(
        request: request,
        selection: selection,
        snapshot: roster.single,
      );
    } on StateError {
      throw const MainlineParticipationRefusedError(
        'Selected mainline participant snapshot cannot be assembled',
      );
    }
  }

  void _validateMode(ActivityParticipationRequest request) {
    if (request.contentKind != ActivityContentKind.mainline ||
        request.participation != ActivityParticipationMode.direct) {
      throw const MainlineParticipationRefusedError(
        'Mainline participation requires direct mainline content',
      );
    }
    final valid = switch (request.entryKind) {
      ActivityEntryKind.firstClear =>
        request.clock == ActivityClock.realtime &&
            request.controller == ActivityController.human,
      ActivityEntryKind.replay =>
        (request.clock == ActivityClock.realtime) ||
            (request.clock == ActivityClock.headless &&
                request.controller == ActivityController.playerBot),
      ActivityEntryKind.sweep =>
        request.clock == ActivityClock.headless &&
            request.controller == ActivityController.playerBot,
      ActivityEntryKind.offlineResume => false,
    };
    if (!valid) {
      throw const MainlineParticipationRefusedError(
        'Mainline participation mode fields are incompatible',
      );
    }
  }

  Future<bool> _isBattleEligible({
    required SaveData? save,
    required int characterId,
  }) async {
    if (save == null || !save.activeCharacterIds.contains(characterId)) {
      return false;
    }
    final character = await _isar.characters.get(characterId);
    if (character == null ||
        !character.isAlive ||
        character.injuryHoursRemaining > 0 ||
        character.mainTechniqueId == null) {
      return false;
    }
    final occupancy = await CharacterOccupancyService(_isar).snapshot();
    if (occupancy.isCharacterOccupied(characterId)) return false;
    return _hasExactLoadout(character);
  }

  Future<bool> _hasExactLoadout(Character character) async {
    for (final equipmentId in [
      character.equippedWeaponId,
      character.equippedArmorId,
      character.equippedAccessoryId,
    ]) {
      if (equipmentId == null) continue;
      final equipment = await _isar.equipments.get(equipmentId);
      if (equipment == null || equipment.ownerCharacterId != character.id) {
        return false;
      }
    }
    for (final techniqueId in [
      character.mainTechniqueId!,
      ...character.assistTechniqueIds,
    ]) {
      final technique = await _isar.techniques.get(techniqueId);
      if (technique == null || technique.ownerCharacterId != character.id) {
        return false;
      }
    }
    return true;
  }
}
