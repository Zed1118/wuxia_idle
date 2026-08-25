import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_assembler.dart';
import '../../lineup/application/disciple_scheduling_provider.dart';

/// 轻功试炼逐次亲战候选。占用、疗养或无主修者保留展示但不可选择。
class LightFootParticipantCandidate {
  const LightFootParticipantCandidate({
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
Future<List<LightFootParticipantCandidate>> loadLightFootParticipantCandidates({
  required Isar isar,
}) async {
  final scheduling = await loadDiscipleSchedulingSummary(isar);
  final candidates = <LightFootParticipantCandidate>[];
  for (final member in scheduling.members) {
    if (!member.isAlive) continue;
    final character = await isar.characters.get(member.characterId);
    if (character == null) {
      throw StateError(
        'Light foot participant disappeared: ${member.characterId}',
      );
    }
    await _validateLightFootParticipantReferences(isar, character);
    candidates.add(
      LightFootParticipantCandidate(
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
///
/// 不读取或写入旧三席阵容；任何状态漂移都拒绝本次进入，不回退掌门。
Future<CombatantSnapshot> resolveLightFootParticipantSnapshot({
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
    throw StateError('Light foot participant is not battle eligible');
  }
  await _validateLightFootParticipantReferences(isar, character);
  final snapshots = await PlayerCombatantSnapshotAssembler(
    isar: isar,
  ).loadExactRoster([requestedParticipantId]);
  if (snapshots.length != 1 ||
      snapshots.single.characterId != requestedParticipantId) {
    throw StateError('Light foot participant snapshot mismatch');
  }
  return snapshots.single;
}

Future<void> _validateLightFootParticipantReferences(
  Isar isar,
  Character character,
) async {
  final mainTechniqueId = character.mainTechniqueId;
  if (mainTechniqueId != null) {
    final technique = await isar.techniques.get(mainTechniqueId);
    if (technique == null || technique.ownerCharacterId != character.id) {
      throw StateError('Light foot participant has invalid main technique');
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
      throw StateError('Light foot participant has invalid equipment');
    }
  }
}

final lightFootParticipantCandidatesProvider =
    FutureProvider<List<LightFootParticipantCandidate>>((ref) {
      return loadLightFootParticipantCandidates(isar: IsarSetup.instance);
    });
