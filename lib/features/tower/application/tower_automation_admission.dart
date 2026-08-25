library;

import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/technique.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/current_leader_resolver.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import '../domain/tower_automation_policy.dart';
import '../domain/tower_progress.dart';
import 'tower_providers.dart';

/// Proof that one typed tower automation request matched current persisted
/// identity, progress, occupancy and exact combat loadout facts.
final class TowerAutomationAdmission {
  const TowerAutomationAdmission._({
    required this.request,
    required this.saveDataId,
    required this.progressId,
    required this.participantCharacterId,
    required this.participantCreatedAt,
    required this.floorIndex,
    required this.currentCycleIndex,
    required this.highestClearedFloor,
    required this.snapshot,
    required this.snapshotSignature,
    required this.equipmentIds,
    required this.techniqueIds,
  });

  final ActivityParticipationRequest request;
  final int saveDataId;
  final int progressId;
  final int participantCharacterId;
  final DateTime participantCreatedAt;
  final int floorIndex;
  final int currentCycleIndex;
  final int highestClearedFloor;
  final CombatantSnapshot snapshot;
  final String snapshotSignature;
  final List<int> equipmentIds;
  final List<int> techniqueIds;
}

/// Application admission in front of the existing tower sweep runner.
///
/// The service owns no persistence and no combat rules. It reuses the current
/// leader resolver and the exact tower participant snapshot owner, then makes
/// the result revalidatable immediately before existing settlement mutates.
final class TowerAutomationAdmissionService {
  const TowerAutomationAdmissionService(this._isar);

  final Isar _isar;

  Future<TowerAutomationAdmission> admit({
    required ActivityParticipationRequest request,
    required int floorIndex,
    required int cycleIndex,
  }) async {
    final save = await _isar.saveDatas.get(0);
    if (save == null) {
      throw StateError('Tower automation admission requires a save');
    }
    final leaderId = await CurrentLeaderResolver.resolve(
      save: save,
      characterExists: (id) async => await _isar.characters.get(id) != null,
    );
    if (request.characterId != leaderId) {
      throw StateError(
        'Tower automation request character is not the current leader',
      );
    }

    final matchingProgress = (await _isar.towerProgress.where().findAll())
        .where((progress) => progress.saveDataId == save.slotId)
        .toList(growable: false);
    if (matchingProgress.length != 1) {
      throw StateError('Tower automation requires one progress record');
    }
    final progress = matchingProgress.single;
    if (progress.currentCycleIndex != cycleIndex) {
      throw StateError('Tower automation cycle admission changed');
    }
    TowerAutomationPolicy.requireAllowed(
      request: request,
      floorIndex: floorIndex,
      highestClearedFloor: progress.highestClearedFloor,
    );

    final character = await _isar.characters.get(leaderId);
    if (character == null) {
      throw StateError('Tower automation participant disappeared');
    }
    final loadout = await _requireExactLoadout(character);
    final occupancy = await CharacterOccupancyService(_isar).snapshot();
    if (occupancy.isCharacterOccupied(character.id) ||
        loadout.equipmentIds.any(occupancy.reservedEquipmentIds.contains) ||
        loadout.techniqueIds.any(occupancy.reservedTechniqueIds.contains)) {
      throw StateError('Tower automation participant loadout is occupied');
    }
    final snapshot = await resolveTowerParticipantSnapshot(
      isar: _isar,
      requestedParticipantId: leaderId,
    );
    if (snapshot.characterId != request.characterId) {
      throw StateError('Tower automation participant snapshot mismatch');
    }

    return TowerAutomationAdmission._(
      request: request,
      saveDataId: save.id,
      progressId: progress.id,
      participantCharacterId: leaderId,
      participantCreatedAt: character.createdAt,
      floorIndex: floorIndex,
      currentCycleIndex: progress.currentCycleIndex,
      highestClearedFloor: progress.highestClearedFloor,
      snapshot: snapshot,
      snapshotSignature: _signature(snapshot),
      equipmentIds: List.unmodifiable(loadout.equipmentIds),
      techniqueIds: List.unmodifiable(loadout.techniqueIds),
    );
  }

  Future<TowerAutomationAdmission> revalidate(
    TowerAutomationAdmission admission,
  ) async {
    final current = await admit(
      request: admission.request,
      floorIndex: admission.floorIndex,
      cycleIndex: admission.currentCycleIndex,
    );
    if (current.saveDataId != admission.saveDataId ||
        current.progressId != admission.progressId ||
        current.participantCharacterId != admission.participantCharacterId ||
        current.participantCreatedAt != admission.participantCreatedAt ||
        current.currentCycleIndex != admission.currentCycleIndex ||
        current.highestClearedFloor != admission.highestClearedFloor ||
        current.snapshotSignature != admission.snapshotSignature ||
        !_sameIds(current.equipmentIds, admission.equipmentIds) ||
        !_sameIds(current.techniqueIds, admission.techniqueIds)) {
      throw StateError('Tower automation admission is stale');
    }
    return current;
  }

  Future<({List<int> equipmentIds, List<int> techniqueIds})>
  _requireExactLoadout(Character character) async {
    if (character.mainTechniqueId == null) {
      throw StateError('Tower automation participant has no main technique');
    }
    final equipmentIds = <int?>[
      character.equippedWeaponId,
      character.equippedArmorId,
      character.equippedAccessoryId,
    ].whereType<int>().toList(growable: false);
    if (equipmentIds.toSet().length != equipmentIds.length) {
      throw StateError('Tower automation participant equipment is duplicated');
    }
    for (final equipmentId in equipmentIds) {
      final equipment = await _isar.equipments.get(equipmentId);
      if (equipment == null || equipment.ownerCharacterId != character.id) {
        throw StateError('Tower automation participant loadout is dangling');
      }
    }
    final techniqueIds = <int>[
      character.mainTechniqueId!,
      ...character.assistTechniqueIds,
    ];
    if (techniqueIds.toSet().length != techniqueIds.length) {
      throw StateError('Tower automation participant technique is duplicated');
    }
    for (final techniqueId in techniqueIds) {
      final technique = await _isar.techniques.get(techniqueId);
      if (technique == null || technique.ownerCharacterId != character.id) {
        throw StateError('Tower automation participant technique is dangling');
      }
    }
    return (equipmentIds: equipmentIds, techniqueIds: techniqueIds);
  }

  static bool _sameIds(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static String _signature(CombatantSnapshot snapshot) {
    String mapSignature(Map<String, int> values) {
      final keys = values.keys.toList()..sort();
      return [for (final key in keys) '$key=${values[key]}'].join(',');
    }

    return <Object?>[
      snapshot.characterId,
      snapshot.name,
      snapshot.realmTier.name,
      snapshot.realmLayer.name,
      snapshot.school.name,
      snapshot.maxHp,
      snapshot.currentHp,
      snapshot.internalForce,
      snapshot.maxQi,
      snapshot.currentQi,
      snapshot.qiGainMultiplier,
      snapshot.qiCostReductionPct,
      snapshot.autoUltimate,
      snapshot.speed,
      snapshot.criticalRate,
      snapshot.evasionRate,
      snapshot.defenseRate,
      snapshot.totalEquipmentAttack,
      snapshot.mainCultivationLayer.name,
      snapshot.skillLoadout.ids.join(','),
      snapshot.availableSkills.map((skill) => skill.id).join(','),
      mapSignature(snapshot.openingSkillCooldowns),
      mapSignature(snapshot.skillUses),
      snapshot.activeBuffs.join(','),
      snapshot.swordSongResonanceActive,
      snapshot.attackPowerMultiplier,
      snapshot.outputMultiplier,
      snapshot.lineageRole?.name,
      snapshot.forgingPiercePct,
      snapshot.forgingLifestealPct,
    ].join('|');
  }
}
