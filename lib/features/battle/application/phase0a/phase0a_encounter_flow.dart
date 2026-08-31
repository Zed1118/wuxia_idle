import '../../domain/phase0a/combat_event_order.dart';
import '../../domain/phase0a/encounter_objective.dart';
import '../../domain/phase0a/objective_controller.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/encounter_enemy_roster.dart';
import '../../domain/phase0a/spawn_director.dart';
import 'phase0a_combat_session.dart';
import 'phase0a_attack_token_lease_batch_receipt.dart';
import 'phase0a_encounter_objective_event_source.dart';
import 'phase0a_encounter_runtime_observation.dart';
import 'phase0a_event_order_adapter.dart';
import '../../domain/phase0a/phase0a_wave.dart' show Phase0aBattleOutcome;
import 'phase0a_battle_flow.dart';
import 'phase0a_enemy_intent_gate.dart';
import 'phase0a_defend_objective_observation.dart';
import 'phase0a_objective_runtime_tracker.dart';
import 'phase0a_player_input_adapter.dart';
import 'phase0a_pursue_objective_observation.dart';
import 'phase0a_spawn_event_adapter.dart';
import 'phase0a_survive_objective_observation.dart';
import 'phase0a_wave_battle_flow.dart';

/// Compatibility seam for the future encounter flow.
///
/// This wrapper deliberately delegates to the legacy wave flow. It does not
/// create another session/reducer, consume encounter directors, or infer any
/// production policy.
final class Phase0aEncounterFlow
    implements
        Phase0aBattleFlow,
        Phase0aEncounterRuntimeObservationSource,
        Phase0aDefendObjectiveObservationSource,
        Phase0aPursueObjectiveObservationSource,
        Phase0aSurviveObjectiveObservationSource {
  Phase0aEncounterFlow.compatibility({required Phase0aWaveBattleFlow legacy})
    : _legacy = legacy,
      _objectiveTracker = null,
      _objectiveEventSource = null;

  Phase0aEncounterFlow.runtime({
    required Phase0aCombatSession session,
    required SpawnDirector director,
    required Phase0aEncounterRoster roster,
    Phase0aObjectiveRuntimeTracker? objectiveTracker,
    Phase0aEncounterObjectiveEventSource? objectiveEventSource,
  }) : _legacy = null,
       _session = session,
       _director = director,
       _roster = roster,
       _objectiveTracker = objectiveTracker,
       _objectiveEventSource = objectiveEventSource {
    if ((objectiveTracker == null) != (objectiveEventSource == null)) {
      throw ArgumentError(
        'objectiveTracker and objectiveEventSource must be configured together',
      );
    }
    if (!identical(roster.director, director)) {
      throw ArgumentError.value(roster, 'roster', 'director identity mismatch');
    }
    if (roster.playerId != session.state.player.id) {
      throw ArgumentError.value(
        roster.playerId,
        'roster',
        'playerId must match session player id',
      );
    }
    if (session.state.player.side != Phase0aSide.player) {
      throw ArgumentError.value(
        session.state.player.id,
        'session',
        'session player must be on the player side',
      );
    }
    if (director.state.tick != session.state.tick) {
      throw ArgumentError.value(
        director.state.tick,
        'director',
        'tick must match session tick',
      );
    }
    final activeIds = director.state.units
        .where((unit) => unit.stage == SpawnUnitStage.active)
        .map((unit) => unit.enemyId)
        .toSet();
    final sessionIds = session.state.enemies.map((enemy) => enemy.id).toSet();
    if (!activeIds.containsAll(sessionIds) ||
        !sessionIds.containsAll(activeIds) ||
        sessionIds.length != session.state.enemies.length) {
      throw ArgumentError.value(
        session.state.enemies,
        'session',
        'session enemies must equal director active units',
      );
    }
    for (final enemy in session.state.enemies) {
      if (enemy.side != Phase0aSide.enemy || !enemy.isAlive) {
        throw ArgumentError.value(
          enemy.id,
          'session',
          'active session enemies must be alive and on the enemy side',
        );
      }
    }
  }

  final Phase0aWaveBattleFlow? _legacy;
  Phase0aCombatSession? _session;
  SpawnDirector? _director;
  Phase0aEncounterRoster? _roster;
  final Phase0aObjectiveRuntimeTracker? _objectiveTracker;
  final Phase0aEncounterObjectiveEventSource? _objectiveEventSource;
  Phase0aBattleOutcome _runtimeOutcome = Phase0aBattleOutcome.ongoing;
  List<CombatEventRecord> _runtimeRecords = const <CombatEventRecord>[];

  @override
  Phase0aArenaState get state => _legacy?.state ?? _session!.state;

  @override
  Phase0aBattleOutcome get outcome => _legacy?.outcome ?? _runtimeOutcome;

  @override
  List<CombatEventRecord> get lastOrderedEventRecords =>
      _legacy?.lastOrderedEventRecords ?? _runtimeRecords;

  ObjectiveControllerProgress? get objectiveProgress =>
      _objectiveTracker?.progress;

  Phase0aAttackTokenLeaseBatchReceipt? get lastAttackTokenLeaseBatchReceipt =>
      _session?.lastAttackTokenLeaseBatchReceipt;

  @override
  Phase0aEncounterRuntimeObservation get runtimeObservation =>
      Phase0aEncounterRuntimeObservation(
        objectiveProgress: objectiveProgress,
        lastAttackTokenLeaseBatchReceipt: lastAttackTokenLeaseBatchReceipt,
      );

  @override
  Phase0aSurviveObjectiveObservation? get surviveObjectiveObservation {
    final tracker = _objectiveTracker;
    if (tracker == null) return null;
    for (var index = 0; index < tracker.controller.clauses.length; index += 1) {
      final objective = tracker.controller.clauses[index].objective;
      if (objective is! SurviveDurationObjective) continue;
      return Phase0aSurviveObjectiveObservation(
        requiredDuration: objective.requiredDuration,
        elapsed: tracker.progress.clauses[index].progress.elapsed,
      );
    }
    return null;
  }

  @override
  Phase0aDefendObjectiveObservation? get defendObjectiveObservation {
    final tracker = _objectiveTracker;
    if (tracker == null) return null;
    for (var index = 0; index < tracker.controller.clauses.length; index += 1) {
      final objective = tracker.controller.clauses[index].objective;
      if (objective is! DefendEntityObjective) continue;
      final defended = state.defendedEntity;
      if (defended == null || defended.id != objective.entityId) {
        throw StateError(
          'Defend entity is not present in the arena: ${objective.entityId}',
        );
      }
      return Phase0aDefendObjectiveObservation(
        entityId: defended.id,
        position: defended.position,
        maxDurability: defended.maxDurability,
        currentDurability: defended.currentDurability,
        requiredDuration: objective.requiredDuration,
        elapsed: tracker.progress.clauses[index].progress.elapsed,
        completed: tracker.progress.clauses[index].completed,
      );
    }
    return null;
  }

  @override
  Phase0aPursueObjectiveObservation? get pursueObjectiveObservation {
    final tracker = _objectiveTracker;
    final roster = _roster;
    if (tracker == null || roster == null) return null;
    for (var index = 0; index < tracker.controller.clauses.length; index += 1) {
      final objective = tracker.controller.clauses[index].objective;
      if (objective is! PursueTargetObjective) continue;
      final binding = roster.bindingByEntryId(objective.targetId);
      if (binding == null) {
        throw StateError(
          'Pursue target is not present in the encounter roster: '
          '${objective.targetId}',
        );
      }
      Phase0aActor? target;
      for (final enemy in state.enemies) {
        if (enemy.id == binding.actorId) {
          target = enemy;
          break;
        }
      }
      return Phase0aPursueObjectiveObservation(
        targetId: objective.targetId,
        targetActorId: binding.actorId,
        distance: target == null
            ? null
            : (target.position - state.player.position).length,
        completed: tracker.progress.clauses[index].completed,
      );
    }
    return null;
  }

  SpawnDirectorState get spawnState {
    final director = _director;
    if (director == null) {
      throw StateError('spawnState is only available for runtime flow');
    }
    return director.state;
  }

  @override
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    final legacy = _legacy;
    if (legacy != null) {
      return legacy.advance(deltaSeconds: deltaSeconds, command: command);
    }
    return _advanceRuntime(deltaSeconds: deltaSeconds, command: command);
  }

  List<Phase0aEvent> _advanceRuntime({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    if (_runtimeOutcome != Phase0aBattleOutcome.ongoing) {
      _runtimeRecords = const <CombatEventRecord>[];
      return const <Phase0aEvent>[];
    }

    final oldSession = _session!;
    final oldDirector = _director!;
    final before = oldSession.state;
    final beforeSpawn = oldDirector.state;
    final step = oldDirector.advance();
    final nextDirector = step.director;
    final combatTick = before.tick + 1;
    if (nextDirector.state.tick != combatTick) {
      throw StateError('director tick must match reducer tick');
    }

    final spawnEvents = Phase0aSpawnEventAdapter.project(
      directorEvents: step.events,
      roster: _roster!,
      seqStart: before.nextSeq,
      combatTick: combatTick,
    );
    final enemies = _arenaEnemies(nextDirector.state, before.enemies);
    final reserved = _copyState(
      before,
      enemies: enemies,
      nextSeq: before.nextSeq + spawnEvents.length,
    );
    final canAttack = nextDirector.state.units
        .where((unit) => unit.canAttack)
        .map((unit) => unit.enemyId)
        .toSet();
    final gatedSession = oldSession.forkWithStateAndEnemyIntentGate(
      reserved,
      enemyIntentGate: Phase0aSpawnGraceIntentGate(
        canAttackActorIds: canAttack,
      ),
    );

    // The existing resolver may consume caller-owned RNG before a later
    // projection fails. It exposes no rewind API, and this flow does not claim
    // to roll that external stream back. All state owned here remains local.
    final combatEvents = gatedSession.advance(
      deltaSeconds: deltaSeconds,
      command: command,
    );
    final playerMovementDelta = gatedSession.playerMovementDeltaFor(
      deltaSeconds: deltaSeconds,
      command: command,
    );
    var directorAfterCombat = nextDirector;
    for (final defeated in combatEvents.whereType<Phase0aEnemyDefeated>()) {
      final binding = _roster!.bindingByEnemyId(defeated.target);
      if (binding == null) {
        throw ArgumentError.value(
          defeated.target,
          'combatEvents',
          'unknown defeated enemy',
        );
      }
      directorAfterCombat = directorAfterCombat.markExited(binding.entryId);
    }

    final resolved = gatedSession.state;
    final events = <Phase0aEvent>[...spawnEvents, ...combatEvents];
    var nextOutcome = Phase0aBattleOutcome.ongoing;
    Phase0aPreparedObjectiveTransition? objectiveTransition;
    final objectiveTracker = _objectiveTracker;
    if (!resolved.player.isAlive) {
      // Defeat is authoritative and deliberately bypasses objective mapping
      // and commit, even if the same frame could otherwise complete it.
      nextOutcome = Phase0aBattleOutcome.defeat;
      events.add(
        Phase0aBattleDefeat(seq: resolved.nextSeq, tick: resolved.tick),
      );
    } else if (resolved.defendedEntity?.isDestroyed == true) {
      nextOutcome = Phase0aBattleOutcome.defeat;
      events.add(
        Phase0aBattleDefeat(seq: resolved.nextSeq, tick: resolved.tick),
      );
    } else if (objectiveTracker != null) {
      if (objectiveTracker.progress.completed) {
        objectiveTransition = objectiveTracker.prepareExternalEvents(
          const <EncounterObjectiveEvent>[],
        );
      } else {
        final frame = Phase0aEncounterObjectiveFrame(
          beforeArena: before,
          afterArena: resolved,
          beforeSpawn: beforeSpawn,
          afterSpawn: directorAfterCombat.state,
          directorEvents: step.events,
          spawnEvents: spawnEvents,
          combatEvents: combatEvents,
          deltaSeconds: deltaSeconds,
          playerMovementDelta: playerMovementDelta,
        );
        objectiveTransition = objectiveTracker.prepareExternalEvents(
          _objectiveEventSource!.eventsFor(frame),
        );
      }
      if (objectiveTransition.next.completed) {
        nextOutcome = Phase0aBattleOutcome.victory;
        events.add(
          Phase0aBattleVictory(seq: resolved.nextSeq, tick: resolved.tick),
        );
      }
    } else if (_surviveReached(resolved) ||
        (directorAfterCombat.state.pendingCount == 0 &&
            directorAfterCombat.state.warningCount == 0 &&
            directorAfterCombat.state.activeCount == 0 &&
            resolved.enemies.isEmpty)) {
      nextOutcome = Phase0aBattleOutcome.victory;
      events.add(
        Phase0aBattleVictory(seq: resolved.nextSeq, tick: resolved.tick),
      );
    }

    final terminalState = events.isEmpty ? null : events.last;
    final nextSeq =
        terminalState is Phase0aBattleVictory ||
            terminalState is Phase0aBattleDefeat
        ? resolved.nextSeq + 1
        : resolved.nextSeq;
    final nextSession = gatedSession.forkWithStateAndEnemyIntentGate(
      _copyState(resolved, nextSeq: nextSeq),
      enemyIntentGate: Phase0aSpawnGraceIntentGate(
        canAttackActorIds: directorAfterCombat.state.units
            .where((unit) => unit.canAttack)
            .map((unit) => unit.enemyId)
            .toSet(),
      ),
    );

    // Finish every potentially throwing projection before the single CAS
    // commit. The assignments after commit only publish already-built values.
    final nextRecords = Phase0aEventOrderAdapter.project(events);
    final returnEvents = List<Phase0aEvent>.unmodifiable(events);
    if (objectiveTransition != null) {
      objectiveTracker!.commit(objectiveTransition);
    }
    _session = nextSession;
    _director = directorAfterCombat;
    _runtimeOutcome = nextOutcome;
    _runtimeRecords = nextRecords;
    return returnEvents;
  }

  List<Phase0aActor> _arenaEnemies(
    SpawnDirectorState state,
    List<Phase0aActor> previousEnemies,
  ) {
    final previousById = {for (final enemy in previousEnemies) enemy.id: enemy};
    return [
      for (final unit in state.units)
        if (unit.stage == SpawnUnitStage.active)
          previousById[unit.enemyId] ??
              _roster!.bindingByEnemyId(unit.enemyId)!.actor,
    ];
  }

  static bool _surviveReached(Phase0aArenaState state) =>
      state.winCondition?.isSurviveTicks == true &&
      state.surviveTicksRemaining == 0 &&
      state.player.isAlive;

  static Phase0aArenaState _copyState(
    Phase0aArenaState state, {
    List<Phase0aActor>? enemies,
    int? nextSeq,
  }) => Phase0aArenaState(
    tick: state.tick,
    nextSeq: nextSeq ?? state.nextSeq,
    player: state.player,
    enemies: enemies ?? state.enemies,
    skillSlots: state.skillSlots,
    defendedEntity: state.defendedEntity,
    winCondition: state.winCondition,
  );
}
