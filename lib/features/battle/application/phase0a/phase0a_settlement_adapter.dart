import '../../../../data/defs/skill_def.dart';
import '../../../../shared/battle_shared/battle_result.dart';
import '../../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_combat_reducer.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import 'phase0a_battle_snapshot_factory.dart';
import 'phase0a_encounter_mapping.dart';
import 'phase0a_stage_content_mapper.dart';

/// Converts Phase 0A terminal state and semantic events into settlement input.
final class Phase0aSettlementAdapter {
  const Phase0aSettlementAdapter._();

  static CombatSettlementSnapshot fromMapping({
    required Phase0aStageMapping mapping,
    required Phase0aBattleOutcome outcome,
    required Phase0aArenaState finalState,
    required List<Phase0aEvent> events,
  }) => _settle(
    playerActorId: mapping.initialState.player.id,
    combatants: mapping.combatants,
    moveBindings: mapping.moveBindings,
    outcome: outcome,
    finalState: finalState,
    events: events,
  );

  static CombatSettlementSnapshot fromEncounterMapping({
    required Phase0aEncounterMapping mapping,
    required Phase0aBattleOutcome outcome,
    required Phase0aArenaState finalState,
    required List<Phase0aEvent> events,
  }) => _settle(
    playerActorId: mapping.initialState.player.id,
    combatants: mapping.combatants,
    moveBindings: mapping.moveBindings,
    outcome: outcome,
    finalState: finalState,
    events: events,
  );

  static CombatSettlementSnapshot _settle({
    required String playerActorId,
    required List<Phase0aCombatantInput> combatants,
    required Map<Phase0aDamageKind, SkillDef?> moveBindings,
    required Phase0aBattleOutcome outcome,
    required Phase0aArenaState finalState,
    required List<Phase0aEvent> events,
  }) {
    final combatantSnapshot = List<Phase0aCombatantInput>.unmodifiable(
      combatants,
    );
    final moveBindingSnapshot = Map<Phase0aDamageKind, SkillDef?>.unmodifiable(
      moveBindings,
    );
    final eventSnapshot = List<Phase0aEvent>.unmodifiable(events);
    if (outcome == Phase0aBattleOutcome.ongoing) {
      throw StateError('Cannot settle an ongoing Phase0a battle');
    }
    if (finalState.player.id != playerActorId ||
        finalState.player.side != Phase0aSide.player) {
      throw StateError(
        'Phase0a settlement player actor mismatch: '
        'expected=$playerActorId, actual=${finalState.player.id}/'
        '${finalState.player.side.name}',
      );
    }
    final mappedPlayerCount = combatantSnapshot
        .where((combatant) => combatant.actorId == playerActorId)
        .length;
    if (mappedPlayerCount != 1) {
      throw StateError(
        'Phase0a settlement requires exactly one mapped player actor: '
        '$playerActorId count=$mappedPlayerCount',
      );
    }
    final characterIdByActor = {
      for (final combatant in combatantSnapshot)
        combatant.actorId: combatant.snapshot.characterId,
    };
    final currentActors = <String, Phase0aActor>{
      finalState.player.id: finalState.player,
      for (final enemy in finalState.enemies) enemy.id: enemy,
    };
    final participants = <CombatParticipantSnapshot>[
      for (final combatant in combatantSnapshot)
        CombatParticipantSnapshot(
          characterId: combatant.snapshot.characterId,
          currentHp: combatant.actorId == playerActorId
              ? finalState.player.currentHealth
              : currentActors[combatant.actorId]?.currentHealth ?? 0,
          maxHp: combatant.snapshot.maxHp,
        ),
    ];

    var totalDamage = 0;
    var criticalCount = 0;
    var hadActions = false;
    final damageByCharacterId = <int, int>{};
    final skillCasts = <CombatSkillCastSnapshot>[];

    void addDamage(String actorId, int damage, {bool critical = false}) {
      totalDamage += damage;
      if (critical) criticalCount += 1;
      final characterId = characterIdByActor[actorId];
      if (characterId == null) return;
      damageByCharacterId.update(
        characterId,
        (total) => total + damage,
        ifAbsent: () => damage,
      );
    }

    void addSkillCastById(
      String actorId,
      int tick,
      String skillId, {
      Phase0aDamageKind? tacticalKind,
    }) {
      final characterId = characterIdByActor[actorId];
      if (characterId == null) return;
      final combatant = combatantSnapshot.firstWhere(
        (entry) => entry.actorId == actorId,
      );
      final ownsSkill = combatant.snapshot.availableSkills.any(
        (skill) => skill.id == skillId,
      );
      final isBasic =
          combatant.snapshot.skillLoadout.basicAttack?.id == skillId;
      final tacticalSkill = tacticalKind == null
          ? null
          : moveBindingSnapshot[tacticalKind];
      final isMappedTactical =
          actorId == playerActorId &&
          tacticalSkill?.id == skillId &&
          tacticalSkill?.source == SkillSource.special &&
          tacticalSkill?.phase0aBehavior != null;
      if (!ownsSkill && !isBasic && !isMappedTactical) {
        return;
      }
      skillCasts.add(
        CombatSkillCastSnapshot(
          tick: tick,
          characterId: characterId,
          skillId: skillId,
        ),
      );
    }

    void addSkillCast(String actorId, int tick, Phase0aDamageKind kind) {
      final skillId = moveBindingSnapshot[kind]?.id;
      if (skillId == null) return;
      addSkillCastById(actorId, tick, skillId);
    }

    for (final event in eventSnapshot) {
      switch (event) {
        case Phase0aAttackStarted(:final actor, :final tick):
          hadActions = true;
          addSkillCast(actor, tick, Phase0aDamageKind.basic);
        case Phase0aHitLanded(
          :final actor,
          :final resolvedDamage,
          :final isCritical,
        ):
          addDamage(actor, resolvedDamage, critical: isCritical);
        case Phase0aGuardianCoopStrike(
          :final mainGuardian,
          :final mainGuardianDamage,
          :final mainGuardianCritical,
        ):
          hadActions = true;
          addDamage(
            mainGuardian,
            mainGuardianDamage,
            critical: mainGuardianCritical,
          );
        case Phase0aGuardIntercepted():
          hadActions = true;
        case Phase0aDefenseStarted():
        case Phase0aDefenseResolved():
          hadActions = true;
        case Phase0aGatherStarted(:final actor, :final tick, :final skillId):
          hadActions = true;
          if (skillId.isNotEmpty) {
            addSkillCastById(
              actor,
              tick,
              skillId,
              tacticalKind: Phase0aDamageKind.gather,
            );
          }
        case Phase0aGatherApplied(:final actor, :final outcomes):
          for (final result in outcomes) {
            addDamage(
              actor,
              result.resolvedDamage,
              critical: result.isCritical,
            );
          }
        case Phase0aClearStarted(:final actor, :final tick, :final skillId):
          hadActions = true;
          if (skillId.isEmpty) {
            addSkillCast(actor, tick, Phase0aDamageKind.clear);
          } else {
            addSkillCastById(
              actor,
              tick,
              skillId,
              tacticalKind: Phase0aDamageKind.clear,
            );
          }
        case Phase0aClearApplied(:final actor, :final outcomes):
          for (final result in outcomes) {
            addDamage(
              actor,
              result.resolvedDamage,
              critical: result.isCritical,
            );
          }
        case Phase0aSkillStarted(:final actor, :final tick, :final skillId):
          hadActions = true;
          addSkillCastById(actor, tick, skillId);
        case Phase0aSkillApplied(:final actor, :final outcomes):
          for (final result in outcomes) {
            addDamage(
              actor,
              result.resolvedDamage,
              critical: result.isCritical,
            );
          }
        case Phase0aBossChargeStarted() || Phase0aEnemySkillStarted():
          hadActions = true;
        case Phase0aEnemyDefeated() ||
            Phase0aBossPhaseChanged() ||
            Phase0aBossChargeInterrupted() ||
            Phase0aSkillAvailabilityChanged() ||
            Phase0aWaveStarted() ||
            Phase0aWaveCleared() ||
            Phase0aSpawnWarningStarted() ||
            Phase0aEnemyEntered() ||
            Phase0aSpawnGraceExpired() ||
            Phase0aBattleVictory() ||
            Phase0aBattleDefeat():
          break;
      }
    }

    return CombatSettlementSnapshot(
      result: switch (outcome) {
        Phase0aBattleOutcome.victory => BattleResult.leftWin,
        Phase0aBattleOutcome.defeat => BattleResult.rightWin,
        Phase0aBattleOutcome.ongoing => null,
      },
      totalTicks: finalState.tick,
      hadActions: hadActions,
      participants: participants,
      skillCasts: skillCasts,
      totalDamage: totalDamage,
      criticalCount: criticalCount,
      damageByCharacterId: damageByCharacterId,
    );
  }
}
