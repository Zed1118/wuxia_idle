import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_assembler.dart';
import '../../lineup/application/disciple_scheduling_provider.dart';

/// 守城试炼逐次亲战候选。占用、疗养或无主修者保留展示但不可选择。
class MassBattleParticipantCandidate {
  const MassBattleParticipantCandidate({
    required this.character,
    required this.occupied,
    required this.healing,
    required this.hasMainTechnique,
  });

  final Character character;
  final bool occupied;
  final bool healing;
  final bool hasMainTechnique;

  bool get selectable => !occupied && !healing && hasMainTechnique;
}

/// 读取当前掌门与当代存活门人，并沿统一调度/占用真相源 fail closed。
Future<List<MassBattleParticipantCandidate>>
loadMassBattleParticipantCandidates({required Isar isar}) async {
  final scheduling = await loadDiscipleSchedulingSummary(isar);
  final candidates = <MassBattleParticipantCandidate>[];
  for (final member in scheduling.members) {
    if (!member.isAlive) continue;
    final character = await isar.characters.get(member.characterId);
    if (character == null) {
      throw StateError(
        'Mass battle participant disappeared: ${member.characterId}',
      );
    }
    await _validateMassBattleParticipantReferences(isar, character);
    candidates.add(
      MassBattleParticipantCandidate(
        character: character,
        occupied: member.activity != null,
        healing: character.injuryHoursRemaining > 0,
        hasMainTechnique: character.mainTechniqueId != null,
      ),
    );
  }
  candidates.sort((left, right) {
    if (left.character.id == scheduling.leaderId) return -1;
    if (right.character.id == scheduling.leaderId) return 1;
    return left.character.id.compareTo(right.character.id);
  });
  return List.unmodifiable(candidates);
}

/// 选人后、进入真实 Phase 0A Host 前再次核验并装配 exact snapshot。
Future<CombatantSnapshot> resolveMassBattleParticipantSnapshot({
  required Isar isar,
  required int requestedParticipantId,
}) async {
  final scheduling = await loadDiscipleSchedulingSummary(isar);
  final member = scheduling.members
      .where((value) => value.characterId == requestedParticipantId)
      .firstOrNull;
  final character = await isar.characters.get(requestedParticipantId);
  if (member == null ||
      !member.isAlive ||
      member.activity != null ||
      character == null ||
      character.injuryHoursRemaining > 0 ||
      character.mainTechniqueId == null) {
    throw StateError('Mass battle participant is not battle eligible');
  }
  await _validateMassBattleParticipantReferences(isar, character);
  final snapshots = await PlayerCombatantSnapshotAssembler(
    isar: isar,
  ).loadExactRoster([requestedParticipantId]);
  if (snapshots.length != 1 ||
      snapshots.single.characterId != requestedParticipantId) {
    throw StateError('Mass battle participant snapshot mismatch');
  }
  return snapshots.single;
}

Future<void> _validateMassBattleParticipantReferences(
  Isar isar,
  Character character,
) async {
  final mainTechniqueId = character.mainTechniqueId;
  if (mainTechniqueId != null) {
    final technique = await isar.techniques.get(mainTechniqueId);
    if (technique == null || technique.ownerCharacterId != character.id) {
      throw StateError('Mass battle participant has invalid main technique');
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
      throw StateError('Mass battle participant has invalid equipment');
    }
  }
}

final massBattleParticipantCandidatesProvider =
    FutureProvider<List<MassBattleParticipantCandidate>>((ref) {
      return loadMassBattleParticipantCandidates(isar: IsarSetup.instance);
    });
