import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/stage_def.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_assembler.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import '../../light_foot/application/light_foot_participant_service.dart';
import '../../lineup/application/disciple_scheduling_provider.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../mass_battle/application/mass_battle_participant_service.dart';
import '../domain/activity_member_snapshot.dart';
import '../domain/activity_occupancy.dart';
import '../domain/durable_activity_automation_policy.dart';
import '../domain/durable_activity_combat_run.dart';
import 'character_occupancy_service.dart';

enum DurableActivitySettlementDisposition { applied, alreadyApplied }

final class DurableActivityAutomationAdmission {
  const DurableActivityAutomationAdmission({
    required this.run,
    required this.request,
    required this.snapshot,
  });

  final DurableActivityCombatRun run;
  final ActivityParticipationRequest request;
  final CombatantSnapshot snapshot;
}

final class DurableActivitySettlementContext {
  const DurableActivitySettlementContext({
    required this.service,
    required this.runId,
  });

  final DurableActivityAutomationService service;
  final int runId;
}

/// 轻功/守城共用的 durable session、occupancy、离线游标与 receipt owner。
final class DurableActivityAutomationService {
  const DurableActivityAutomationService(this._isar);

  final Isar _isar;

  Future<DurableActivityCombatRun?> runById(int runId) =>
      _isar.durableActivityCombatRuns.get(runId);

  Future<DurableActivityCombatRun?> outstandingForKind(
    DurableActivityKind kind,
  ) async {
    final save = await _isar.saveDatas.get(0);
    if (save == null) return null;
    final matches = (await _isar.durableActivityCombatRuns.where().findAll())
        .where(
          (run) =>
              run.saveDataId == save.id &&
              run.kind == kind &&
              run.phase != DurableActivityPhase.closed,
        )
        .toList(growable: false);
    if (matches.length > 1) {
      throw StateError('Multiple outstanding ${kind.name} automation runs');
    }
    return matches.firstOrNull;
  }

  Future<int> start({
    required DurableActivityKind kind,
    required StageDef stage,
    required int cycleIndex,
    required ActivityParticipationRequest request,
    Formation? formation,
    DateTime? now,
  }) async {
    if (cycleIndex < 1) {
      throw ArgumentError.value(cycleIndex, 'cycleIndex', 'must be >= 1');
    }
    final save = await _isar.saveDatas.get(0);
    if (save == null) {
      throw StateError('Durable activity automation requires a save');
    }
    final progress = await _progressFor(save.slotId);
    DurableActivityAutomationPolicy.requireAllowed(
      kind: kind,
      stage: stage,
      request: request,
      alreadyCleared: progress.clearedStageIds.contains(stage.id),
      formation: formation,
    );

    final snapshot = switch (kind) {
      DurableActivityKind.lightFoot =>
        await resolveLightFootParticipantSnapshot(
          isar: _isar,
          requestedParticipantId: request.characterId,
        ),
      DurableActivityKind.massBattle =>
        await resolveMassBattleParticipantSnapshot(
          isar: _isar,
          requestedParticipantId: request.characterId,
        ),
    };
    final startedAt = now ?? DateTime.now();

    return _isar.writeTxn(() async {
      final currentSave = await _isar.saveDatas.get(0);
      if (currentSave == null || currentSave.id != save.id) {
        throw StateError('Durable activity save identity changed');
      }
      final outstanding =
          (await _isar.durableActivityCombatRuns.where().findAll())
              .where(
                (run) =>
                    run.saveDataId == save.id &&
                    run.phase != DurableActivityPhase.closed,
              )
              .toList(growable: false);
      if (outstanding.isNotEmpty) {
        throw StateError('Another durable activity automation run is active');
      }
      final currentProgress = await _progressFor(currentSave.slotId);
      DurableActivityAutomationPolicy.requireAllowed(
        kind: kind,
        stage: stage,
        request: request,
        alreadyCleared: currentProgress.clearedStageIds.contains(stage.id),
        formation: formation,
      );
      final scheduling = await loadDiscipleSchedulingSummary(_isar);
      final scheduled = scheduling.members
          .where((member) => member.characterId == request.characterId)
          .toList(growable: false);
      if (scheduled.length != 1 ||
          !scheduled.single.isAlive ||
          scheduled.single.activity != null) {
        throw StateError('Durable activity participant is not available');
      }
      final character = await _requireCharacter(request.characterId);
      final member = await _validatedMember(character, snapshot: snapshot);

      final run = DurableActivityCombatRun()
        ..saveDataId = save.id
        ..kind = kind
        ..contentId = request.contentId
        ..loadoutPlanId = request.loadoutPlanId
        ..stageId = stage.id
        ..cycleIndex = cycleIndex
        ..seed = 0
        ..contentKind = request.contentKind
        ..participation = request.participation
        ..controller = request.controller
        ..clock = request.clock
        ..entryKind = request.entryKind
        ..members = [member]
        ..participantCreatedAt = character.createdAt
        ..participantName = snapshot.name
        ..formation = formation
        ..phase = DurableActivityPhase.active
        ..outcome = DurableActivityOutcome.none
        ..startedAt = startedAt
        ..lastAdvancedAt = startedAt;
      final runId = await _isar.durableActivityCombatRuns.put(run);
      run.seed = runId;
      await _isar.durableActivityCombatRuns.put(run);
      return runId;
    });
  }

  Future<DurableActivityAutomationAdmission> admit({
    required int runId,
    required StageDef stage,
    DateTime? now,
  }) async {
    final run = await _isar.durableActivityCombatRuns.get(runId);
    if (run == null || run.phase != DurableActivityPhase.active) {
      throw StateError('Durable activity automation run is not active');
    }
    if (run.stageId != stage.id || run.contentId != stage.id) {
      throw StateError('Durable activity stage identity changed');
    }
    if (run.members.length != 1) {
      throw StateError('Durable activity requires exactly one member');
    }
    final save = await _isar.saveDatas.get(0);
    if (save == null || save.id != run.saveDataId) {
      throw StateError('Durable activity save identity changed');
    }
    final progress = await _progressFor(save.slotId);
    DurableActivityAutomationPolicy.requireAllowed(
      kind: run.kind,
      stage: stage,
      request: run.request,
      alreadyCleared: progress.clearedStageIds.contains(stage.id),
      formation: run.formation,
    );
    final activityKind = switch (run.kind) {
      DurableActivityKind.lightFoot => ActivityKind.lightFoot,
      DurableActivityKind.massBattle => ActivityKind.massBattle,
    };
    final occupancy = await CharacterOccupancyService(
      _isar,
    ).snapshot(excludingKind: activityKind, excludingRunId: run.id);
    final member = run.members.single;
    if (occupancy.isCharacterOccupied(member.characterId) ||
        member.reservedEquipmentIds.any(
          occupancy.reservedEquipmentIds.contains,
        ) ||
        member.reservedTechniqueIds.any(
          occupancy.reservedTechniqueIds.contains,
        )) {
      throw StateError('Durable activity participant loadout is occupied');
    }
    final scheduling = await loadDiscipleSchedulingSummary(_isar);
    final scheduled = scheduling.members
        .where((value) => value.characterId == member.characterId)
        .toList(growable: false);
    final character = await _requireCharacter(member.characterId);
    if (scheduled.length != 1 ||
        !scheduled.single.isAlive ||
        character.createdAt != run.participantCreatedAt) {
      throw StateError('Durable activity participant identity changed');
    }
    final currentMember = await _validatedMember(character);
    if (!_sameIds(
          currentMember.reservedEquipmentIds,
          member.reservedEquipmentIds,
        ) ||
        !_sameIds(
          currentMember.reservedTechniqueIds,
          member.reservedTechniqueIds,
        )) {
      throw StateError('Durable activity participant loadout changed');
    }
    final snapshots = await PlayerCombatantSnapshotAssembler(
      isar: _isar,
    ).loadExactRoster([member.characterId]);
    if (snapshots.length != 1 ||
        snapshots.single.characterId != member.characterId) {
      throw StateError('Durable activity participant snapshot mismatch');
    }
    final advancedAt = now ?? DateTime.now();
    await _isar.writeTxn(() async {
      final current = await _isar.durableActivityCombatRuns.get(run.id);
      if (current == null || current.phase != DurableActivityPhase.active) {
        throw StateError('Durable activity run changed before execution');
      }
      current.lastAdvancedAt = advancedAt;
      await _isar.durableActivityCombatRuns.put(current);
    });
    final refreshed = await _isar.durableActivityCombatRuns.get(run.id);
    if (refreshed == null) {
      throw StateError('Durable activity run disappeared');
    }
    return DurableActivityAutomationAdmission(
      run: refreshed,
      request: refreshed.request,
      snapshot: snapshots.single,
    );
  }

  Future<DurableActivitySettlementDisposition> commitSettlement({
    required int runId,
    required DurableActivityOutcome outcome,
    required Future<void> Function() applyInTxn,
    DateTime? now,
  }) async {
    if (outcome == DurableActivityOutcome.none) {
      throw ArgumentError.value(outcome, 'outcome', 'must be terminal');
    }
    var disposition = DurableActivitySettlementDisposition.alreadyApplied;
    final appliedAt = now ?? DateTime.now();
    await _isar.writeTxn(() async {
      final run = await _isar.durableActivityCombatRuns.get(runId);
      if (run == null) {
        throw StateError('Durable activity settlement run does not exist');
      }
      if (run.phase == DurableActivityPhase.settlementApplied ||
          run.phase == DurableActivityPhase.closed) {
        return;
      }
      if (run.phase != DurableActivityPhase.active) {
        throw StateError('Durable activity settlement phase is invalid');
      }
      await applyInTxn();
      run.phase = DurableActivityPhase.settlementApplied;
      run.outcome = outcome;
      run.settlementAppliedAt = appliedAt;
      run.lastAdvancedAt = appliedAt;
      await _isar.durableActivityCombatRuns.put(run);
      disposition = DurableActivitySettlementDisposition.applied;
    });
    return disposition;
  }

  Future<void> close({required int runId, DateTime? now}) async {
    final closedAt = now ?? DateTime.now();
    await _isar.writeTxn(() async {
      final run = await _isar.durableActivityCombatRuns.get(runId);
      if (run == null) return;
      if (run.phase == DurableActivityPhase.closed) return;
      if (run.phase != DurableActivityPhase.settlementApplied) {
        throw StateError('Only a settled durable activity run can close');
      }
      run.phase = DurableActivityPhase.closed;
      run.closedAt = closedAt;
      await _isar.durableActivityCombatRuns.put(run);
    });
  }

  Future<MainlineProgress> _progressFor(int saveDataId) async {
    final matches = (await _isar.mainlineProgress.where().findAll())
        .where((progress) => progress.saveDataId == saveDataId)
        .toList(growable: false);
    if (matches.length != 1) {
      throw StateError('Durable activity requires one progress record');
    }
    return matches.single;
  }

  Future<Character> _requireCharacter(int characterId) async {
    final character = await _isar.characters.get(characterId);
    if (character == null ||
        !character.isAlive ||
        character.injuryHoursRemaining > 0 ||
        character.mainTechniqueId == null) {
      throw StateError('Durable activity participant is not battle eligible');
    }
    return character;
  }

  Future<ActivityMemberSnapshot> _validatedMember(
    Character character, {
    CombatantSnapshot? snapshot,
  }) async {
    final equipmentIds = <int>[
      ?character.equippedWeaponId,
      ?character.equippedArmorId,
      ?character.equippedAccessoryId,
    ];
    if (equipmentIds.toSet().length != equipmentIds.length) {
      throw StateError('Durable activity equipment references are duplicated');
    }
    for (final equipmentId in equipmentIds) {
      final equipment = await _isar.equipments.get(equipmentId);
      if (equipment == null || equipment.ownerCharacterId != character.id) {
        throw StateError('Durable activity equipment reference is invalid');
      }
    }
    final mainTechniqueId = character.mainTechniqueId!;
    final techniqueIds = <int>[
      mainTechniqueId,
      ...character.assistTechniqueIds,
    ];
    if (techniqueIds.toSet().length != techniqueIds.length) {
      throw StateError('Durable activity technique references are duplicated');
    }
    for (final techniqueId in techniqueIds) {
      final technique = await _isar.techniques.get(techniqueId);
      if (technique == null || technique.ownerCharacterId != character.id) {
        throw StateError('Durable activity technique reference is invalid');
      }
    }
    return ActivityMemberSnapshot()
      ..characterId = character.id
      ..reservedEquipmentIds = equipmentIds
      ..reservedTechniqueIds = techniqueIds
      ..currentHp = snapshot?.currentHp ?? 0
      ..currentQi = snapshot?.currentQi ?? 0
      ..maxHp = snapshot?.maxHp ?? 0
      ..maxQi = snapshot?.maxQi ?? 0
      ..isDowned = false;
  }

  static bool _sameIds(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
