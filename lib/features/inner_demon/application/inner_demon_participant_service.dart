import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_assembler.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import '../../lineup/application/disciple_scheduling_provider.dart';
import '../domain/inner_demon_participation_policy.dart';

/// Resolves the exact current-generation person selected by the character
/// panel. Eligibility is rechecked immediately before the existing live stage
/// flow starts, so stale UI state never falls back to another character.
Future<CombatantSnapshot> resolveInnerDemonParticipantSnapshot({
  required Isar isar,
  required ActivityParticipationRequest request,
  required String expectedStageId,
  required int expectedCharacterId,
}) async {
  final decision = InnerDemonParticipationPolicy.evaluate(
    request: request,
    expectedStageId: expectedStageId,
    expectedCharacterId: expectedCharacterId,
  );
  if (!decision.allowed) {
    throw StateError(
      'Inner demon participation refused: ${decision.rejectionReason}',
    );
  }

  final scheduling = await loadDiscipleSchedulingSummary(isar);
  final member = scheduling.members
      .where((value) => value.characterId == expectedCharacterId)
      .firstOrNull;
  final character = await isar.characters.get(expectedCharacterId);
  if (member == null ||
      !member.isAlive ||
      member.activity != null ||
      character == null ||
      !character.isAlive ||
      character.injuryHoursRemaining > 0 ||
      character.mainTechniqueId == null) {
    throw StateError('Inner demon participant is not battle eligible');
  }
  await _validateInnerDemonParticipantReferences(isar, character);

  final snapshots = await PlayerCombatantSnapshotAssembler(
    isar: isar,
  ).loadExactRoster([expectedCharacterId]);
  if (snapshots.length != 1 ||
      snapshots.single.characterId != expectedCharacterId) {
    throw StateError('Inner demon participant snapshot mismatch');
  }
  return snapshots.single;
}

Future<void> _validateInnerDemonParticipantReferences(
  Isar isar,
  Character character,
) async {
  for (final techniqueId in [
    character.mainTechniqueId!,
    ...character.assistTechniqueIds,
  ]) {
    final technique = await isar.techniques.get(techniqueId);
    if (technique == null || technique.ownerCharacterId != character.id) {
      throw StateError('Inner demon participant has invalid technique');
    }
  }
  for (final equipmentId in [
    character.equippedWeaponId,
    character.equippedArmorId,
    character.equippedAccessoryId,
  ]) {
    if (equipmentId == null) continue;
    final equipment = await isar.equipments.get(equipmentId);
    if (equipment == null || equipment.ownerCharacterId != character.id) {
      throw StateError('Inner demon participant has invalid equipment');
    }
  }
}
