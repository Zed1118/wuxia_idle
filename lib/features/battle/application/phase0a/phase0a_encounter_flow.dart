import '../../domain/phase0a/combat_event_order.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/encounter_enemy_roster.dart';
import '../../domain/phase0a/spawn_director.dart';
import 'phase0a_combat_session.dart';
import 'phase0a_event_order_adapter.dart';
import '../../domain/phase0a/phase0a_wave.dart' show Phase0aBattleOutcome;
import 'phase0a_battle_flow.dart';
import 'phase0a_enemy_intent_gate.dart';
import 'phase0a_player_input_adapter.dart';
import 'phase0a_spawn_event_adapter.dart';
import 'phase0a_wave_battle_flow.dart';

/// Compatibility seam for the future encounter flow.
///
/// This wrapper deliberately delegates to the legacy wave flow. It does not
/// create another session/reducer, consume encounter directors, or infer any
/// production policy.
final class Phase0aEncounterFlow implements Phase0aBattleFlow {
  Phase0aEncounterFlow.compatibility({required Phase0aWaveBattleFlow legacy})
    : _legacy = legacy;

  Phase0aEncounterFlow.runtime({
    required Phase0aCombatSession session,
    required SpawnDirector director,
    required Phase0aEncounterRoster roster,
  }) : _legacy = null,
       _session = session,
       _director = director,
       _roster = roster {
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
  Phase0aBattleOutcome _runtimeOutcome = Phase0aBattleOutcome.ongoing;
  List<CombatEventRecord> _runtimeRecords = const <CombatEventRecord>[];

  @override
  Phase0aArenaState get state => _legacy?.state ?? _session!.state;

  @override
  Phase0aBattleOutcome get outcome => _legacy?.outcome ?? _runtimeOutcome;

  @override
  List<CombatEventRecord> get lastOrderedEventRecords =>
      _legacy?.lastOrderedEventRecords ?? _runtimeRecords;

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
    final oldOutcome = _runtimeOutcome;
    final oldRecords = _runtimeRecords;
    try {
      final before = oldSession.state;
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
      final combatEvents = gatedSession.advance(
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

      final events = <Phase0aEvent>[...spawnEvents, ...combatEvents];
      final resolved = gatedSession.state;
      if (!resolved.player.isAlive) {
        _runtimeOutcome = Phase0aBattleOutcome.defeat;
        events.add(
          Phase0aBattleDefeat(seq: resolved.nextSeq, tick: resolved.tick),
        );
      } else if (_surviveReached(resolved)) {
        _runtimeOutcome = Phase0aBattleOutcome.victory;
        events.add(
          Phase0aBattleVictory(seq: resolved.nextSeq, tick: resolved.tick),
        );
      } else if (directorAfterCombat.state.pendingCount == 0 &&
          directorAfterCombat.state.warningCount == 0 &&
          directorAfterCombat.state.activeCount == 0 &&
          resolved.enemies.isEmpty) {
        _runtimeOutcome = Phase0aBattleOutcome.victory;
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
      _session = gatedSession.forkWithStateAndEnemyIntentGate(
        _copyState(resolved, nextSeq: nextSeq),
        enemyIntentGate: Phase0aSpawnGraceIntentGate(
          canAttackActorIds: directorAfterCombat.state.units
              .where((unit) => unit.canAttack)
              .map((unit) => unit.enemyId)
              .toSet(),
        ),
      );
      _director = directorAfterCombat;
      _runtimeRecords = Phase0aEventOrderAdapter.project(events);
      return List.unmodifiable(events);
    } catch (_) {
      _session = oldSession;
      _director = oldDirector;
      _runtimeOutcome = oldOutcome;
      _runtimeRecords = oldRecords;
      rethrow;
    }
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
    winCondition: state.winCondition,
  );
}
