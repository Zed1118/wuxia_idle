import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_objective_runtime_tracker.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/objective_controller.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';

Phase0aActor _actor(
  String id, {
  required Phase0aSide side,
  int health = 100,
  ArenaVector position = const ArenaVector(50, 0),
}) => Phase0aActor(
  id: id,
  side: side,
  position: position,
  facing: const ArenaVector(1, 0),
  maxHealth: 100,
  currentHealth: health,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aActor _actorWithMutableContainers(
  String id, {
  required Phase0aSide side,
  ArenaVector position = const ArenaVector(50, 0),
}) => Phase0aActor(
  id: id,
  side: side,
  position: position,
  facing: const ArenaVector(1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
  bossPhases: [
    BossPhaseDef(hpThresholdPct: 1, unlockSkillIds: ['phase-skill-$id']),
  ],
  unlockedEnemySkillIds: ['unlocked-skill-$id'],
  enemySkillCooldowns: {'cooldown-skill-$id': 1},
  phaseChargeCasts: [null],
  guardianDefIds: ['guardian-$id'],
);

Map<String, Object?> _actorContainerSnapshot(Phase0aActor actor) => {
  'bossPhases': [
    for (final phase in actor.bossPhases!) [...phase.unlockSkillIds],
  ],
  'unlockedEnemySkillIds': [...actor.unlockedEnemySkillIds],
  'enemySkillCooldowns': {...actor.enemySkillCooldowns},
  'phaseChargeCastsLength': actor.phaseChargeCasts.length,
  'guardianDefIds': [...actor.guardianDefIds],
};

void _expectActorContainersImmutable(Phase0aActor actor) {
  expect(() => actor.bossPhases!.clear(), throwsUnsupportedError);
  expect(
    () => actor.bossPhases!.single.unlockSkillIds.clear(),
    throwsUnsupportedError,
  );
  expect(() => actor.unlockedEnemySkillIds.clear(), throwsUnsupportedError);
  expect(() => actor.enemySkillCooldowns.clear(), throwsUnsupportedError);
  expect(() => actor.phaseChargeCasts.clear(), throwsUnsupportedError);
  expect(() => actor.guardianDefIds.clear(), throwsUnsupportedError);
}

void _attemptAllActorContainerMutations(Phase0aActor actor) {
  void attempt(void Function() mutate) {
    try {
      mutate();
    } on UnsupportedError {
      // Expected from a genuinely immutable frame snapshot.
    }
  }

  attempt(() => actor.bossPhases!.single.unlockSkillIds.clear());
  attempt(() => actor.bossPhases!.clear());
  attempt(() => actor.unlockedEnemySkillIds.clear());
  attempt(() => actor.enemySkillCooldowns.clear());
  attempt(() => actor.phaseChargeCasts.clear());
  attempt(() => actor.guardianDefIds.clear());
}

final class _FixedResolver implements Phase0aDamageResolver {
  const _FixedResolver({this.damage = 0, this.playerOnly = false});

  final int damage;
  final bool playerOnly;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    required double defenderWardMult,
  }) {
    final resolvedDamage = playerOnly && attackerId != 'player' ? 0 : damage;
    return Phase0aResolvedHit(
      isHit: resolvedDamage > 0,
      isCritical: false,
      damage: resolvedDamage,
    );
  }
}

final class _CallbackSource implements Phase0aEncounterObjectiveEventSource {
  _CallbackSource(this.callback);

  final Iterable<EncounterObjectiveEvent> Function(
    Phase0aEncounterObjectiveFrame frame,
  )
  callback;
  final List<Phase0aEncounterObjectiveFrame> frames = [];

  @override
  Iterable<EncounterObjectiveEvent> eventsFor(
    Phase0aEncounterObjectiveFrame frame,
  ) {
    frames.add(frame);
    return callback(frame);
  }
}

Phase0aObjectiveRuntimeTracker _tracker(
  Iterable<ObjectiveClause> clauses, {
  ObjectiveCompletionRule rule = ObjectiveCompletionRule.all,
}) => Phase0aObjectiveRuntimeTracker(
  controller: ObjectiveController(completionRule: rule, clauses: clauses),
);

final class _Fixture {
  _Fixture({
    int enemyCount = 1,
    int damage = 0,
    bool playerOnly = false,
    int attackGraceTicks = 1,
    int playerHealth = 100,
    int nextSeq = 0,
    Phase0aWinCondition? winCondition,
    Phase0aObjectiveRuntimeTracker? objectiveTracker,
    Phase0aEncounterObjectiveEventSource? objectiveEventSource,
    bool passObjectiveArguments = true,
    bool startWithActiveEnemy = false,
    Phase0aActor? player,
    Phase0aActor Function(String enemyId)? enemyActorFactory,
  }) {
    var preparedDirector = SpawnDirector(
      config: SpawnDirectorConfig(
        activeLimit: 1,
        reinforcementThreshold: 0,
        entryWarningTicks: 0,
        attackGraceTicks: attackGraceTicks,
      ),
      entries: [
        for (var index = 1; index <= enemyCount; index += 1)
          SpawnEntry(entryId: 'entry_$index', enemyId: 'enemy_$index'),
      ],
    );
    if (startWithActiveEnemy) {
      preparedDirector = preparedDirector.advance().director;
    }
    director = preparedDirector;
    final actorsByEnemyId = {
      for (final unit in director.state.units)
        unit.enemyId:
            enemyActorFactory?.call(unit.enemyId) ??
            _actor(unit.enemyId, side: Phase0aSide.enemy),
    };
    roster = Phase0aEncounterRoster(
      director: director,
      playerId: 'player',
      bindings: [
        for (final unit in director.state.units)
          Phase0aEncounterRosterBinding(
            entryId: unit.entryId,
            actor: actorsByEnemyId[unit.enemyId]!,
          ),
      ],
    );
    final session = Phase0aCombatSession(
      initialState: Phase0aArenaState(
        tick: director.state.tick,
        nextSeq: nextSeq,
        player:
            player ??
            _actor(
              'player',
              side: Phase0aSide.player,
              health: playerHealth,
              position: ArenaVector.zero,
            ),
        enemies: [
          for (final unit in director.state.units)
            if (unit.stage == SpawnUnitStage.active)
              actorsByEnemyId[unit.enemyId]!,
        ],
        skillSlots: const [],
        winCondition: winCondition,
      ),
      playerAdapter: const Phase0aPlayerInputAdapter(
        playerId: 'player',
        attackRange: 100,
        attackHalfArcRadians: 3.14,
        attackCooldownSeconds: 0,
        attackQiDelta: 0,
        postureBasicPowerMultiplier: 1,
        attackPowerMultiplier: 1,
        gatherPowerMultiplier: 1,
        clearPowerMultiplier: 1,
        gatherSlot: 'gather',
        gatherRingRadius: 1,
        gatherEffectRadius: 1,
        gatherQiCost: 0,
        gatherCooldownSeconds: 0,
        clearSlot: 'clear',
        clearEffectRadius: 1,
        clearQiCost: 0,
        clearCooldownSeconds: 0,
      ),
      enemyAiAdapter: const Phase0aEnemyAiAdapter(
        attackRange: 100,
        attackHalfArcRadians: 3.14,
        attackCooldownSeconds: 0,
        postureBasicPowerMultiplier: 1,
        uniformBasicPowerMultiplier: 1,
      ),
      damageResolver: _FixedResolver(damage: damage, playerOnly: playerOnly),
    );
    flow = passObjectiveArguments
        ? Phase0aEncounterFlow.runtime(
            session: session,
            director: director,
            roster: roster,
            objectiveTracker: objectiveTracker,
            objectiveEventSource: objectiveEventSource,
          )
        : Phase0aEncounterFlow.runtime(
            session: session,
            director: director,
            roster: roster,
          );
  }

  late final SpawnDirector director;
  late final Phase0aEncounterRoster roster;
  late final Phase0aEncounterFlow flow;
}

const _idle = Phase0aPlayerCommand();
const _attack = Phase0aPlayerCommand(attack: true);

void main() {
  test('objective tracker and source must be configured together', () {
    final tracker = _tracker([
      ObjectiveClause(
        id: 'target',
        objective: DefeatTargetsObjective(const ['target']),
      ),
    ]);
    final source = _CallbackSource((_) => const <EncounterObjectiveEvent>[]);

    expect(() => _Fixture(objectiveTracker: tracker), throwsArgumentError);
    expect(() => _Fixture(objectiveEventSource: source), throwsArgumentError);
  });

  test(
    'explicit target and commander source completes from immutable facts',
    () {
      final tracker = _tracker([
        ObjectiveClause(
          id: 'target',
          objective: DefeatTargetsObjective(const ['target-bandit']),
        ),
        ObjectiveClause(
          id: 'commander',
          objective: DefeatCommanderObjective('commander-bandit'),
        ),
      ]);
      final source = _CallbackSource((frame) sync* {
        for (final defeat
            in frame.combatEvents.whereType<Phase0aEnemyDefeated>()) {
          if (defeat.target == 'enemy_1') {
            yield TargetDefeated(
              'target-bandit',
              eventId: 'target:${defeat.seq}',
            );
            yield CommanderDefeated(
              'commander-bandit',
              eventId: 'commander:${defeat.seq}',
            );
          }
        }
      });
      final fixture = _Fixture(
        damage: 100,
        playerOnly: true,
        objectiveTracker: tracker,
        objectiveEventSource: source,
      );

      final events = fixture.flow.advance(deltaSeconds: 1, command: _attack);

      expect(fixture.flow.outcome, Phase0aBattleOutcome.victory);
      expect(events.last, isA<Phase0aBattleVictory>());
      expect(tracker.progress.completed, isTrue);
      final frame = source.frames.single;
      expect(frame.deltaSeconds, 1);
      expect(frame.beforeArena.tick, 0);
      expect(frame.afterArena.tick, 1);
      expect(frame.beforeSpawn.pendingCount, 1);
      expect(frame.afterSpawn.removedCount, 1);
      expect(frame.directorEvents.single.type, SpawnDirectorEventType.entered);
      expect(frame.spawnEvents.single, isA<Phase0aEnemyEntered>());
      expect(
        frame.combatEvents.whereType<Phase0aEnemyDefeated>(),
        hasLength(1),
      );
      expect(() => frame.directorEvents.clear(), throwsUnsupportedError);
      expect(() => frame.spawnEvents.clear(), throwsUnsupportedError);
      expect(() => frame.combatEvents.clear(), throwsUnsupportedError);
      expect(() => frame.afterArena.enemies.clear(), throwsUnsupportedError);
    },
  );

  test(
    'frame deeply freezes every public actor container before and after',
    () {
      final player = _actorWithMutableContainers(
        'player',
        side: Phase0aSide.player,
        position: ArenaVector.zero,
      );
      late final Phase0aActor enemy;
      final playerContainers = _actorContainerSnapshot(player);
      final tracker = _tracker([
        ObjectiveClause(
          id: 'target',
          objective: DefeatTargetsObjective(const ['unreached-target']),
        ),
      ]);
      final source = _CallbackSource((frame) {
        expect(frame.beforeArena.player, isNot(same(player)));
        expect(frame.afterArena.player, isNot(same(player)));
        expect(frame.beforeArena.enemies.single, isNot(same(enemy)));
        expect(frame.afterArena.enemies.single, isNot(same(enemy)));
        _expectActorContainersImmutable(frame.beforeArena.player);
        _expectActorContainersImmutable(frame.beforeArena.enemies.single);
        _expectActorContainersImmutable(frame.afterArena.player);
        _expectActorContainersImmutable(frame.afterArena.enemies.single);
        return const <EncounterObjectiveEvent>[];
      });
      final fixture = _Fixture(
        startWithActiveEnemy: true,
        player: player,
        enemyActorFactory: (enemyId) => enemy = _actorWithMutableContainers(
          enemyId,
          side: Phase0aSide.enemy,
        ),
        objectiveTracker: tracker,
        objectiveEventSource: source,
      );
      final enemyContainers = _actorContainerSnapshot(enemy);

      fixture.flow.advance(deltaSeconds: 1, command: _idle);

      expect(fixture.flow.outcome, Phase0aBattleOutcome.ongoing);
      expect(_actorContainerSnapshot(player), playerContainers);
      expect(_actorContainerSnapshot(enemy), enemyContainers);
    },
  );

  test('mutation attempts then source failure cannot alias old state', () {
    final player = _actorWithMutableContainers(
      'player',
      side: Phase0aSide.player,
      position: ArenaVector.zero,
    );
    late final Phase0aActor enemy;
    final tracker = _tracker([
      ObjectiveClause(
        id: 'target',
        objective: DefeatTargetsObjective(const ['unreached-target']),
      ),
    ]);
    final source = _CallbackSource((frame) {
      for (final actor in [
        frame.beforeArena.player,
        ...frame.beforeArena.enemies,
        frame.afterArena.player,
        ...frame.afterArena.enemies,
      ]) {
        _attemptAllActorContainerMutations(actor);
      }
      throw StateError('source failure after mutation attempts');
    });
    final fixture = _Fixture(
      startWithActiveEnemy: true,
      player: player,
      enemyActorFactory: (enemyId) =>
          enemy = _actorWithMutableContainers(enemyId, side: Phase0aSide.enemy),
      objectiveTracker: tracker,
      objectiveEventSource: source,
    );
    final state = fixture.flow.state;
    final playerContainers = _actorContainerSnapshot(state.player);
    final enemyContainers = _actorContainerSnapshot(state.enemies.single);
    final spawnState = fixture.flow.spawnState;
    final outcome = fixture.flow.outcome;
    final records = fixture.flow.lastOrderedEventRecords;
    final progress = tracker.progress;

    expect(
      () => fixture.flow.advance(deltaSeconds: 1, command: _idle),
      throwsStateError,
    );

    expect(fixture.flow.state, same(state));
    expect(_actorContainerSnapshot(state.player), playerContainers);
    expect(_actorContainerSnapshot(state.enemies.single), enemyContainers);
    expect(fixture.flow.spawnState.tick, spawnState.tick);
    expect(fixture.flow.spawnState.units, spawnState.units);
    expect(fixture.flow.outcome, outcome);
    expect(fixture.flow.lastOrderedEventRecords, same(records));
    expect(tracker.progress, same(progress));
    expect(_actorContainerSnapshot(player), playerContainers);
    expect(_actorContainerSnapshot(enemy), enemyContainers);
  });

  test('caller may emit an explicit checkpoint only after two kills', () {
    final tracker = _tracker([
      ObjectiveClause(
        id: 'checkpoint',
        objective: ReachCheckpointObjective(const ['after-two-kills']),
      ),
    ]);
    final source = _CallbackSource((frame) {
      return frame.afterSpawn.removedCount >= 2
          ? [
              CheckpointReached(
                'after-two-kills',
                eventId: 'checkpoint:after-two-kills',
              ),
            ]
          : const <EncounterObjectiveEvent>[];
    });
    final fixture = _Fixture(
      enemyCount: 2,
      damage: 100,
      playerOnly: true,
      objectiveTracker: tracker,
      objectiveEventSource: source,
    );

    fixture.flow.advance(deltaSeconds: 1, command: _attack);
    expect(fixture.flow.outcome, Phase0aBattleOutcome.ongoing);
    expect(tracker.progress.completed, isFalse);
    fixture.flow.advance(deltaSeconds: 1, command: _idle);
    final terminal = fixture.flow.advance(deltaSeconds: 1, command: _attack);

    expect(fixture.flow.outcome, Phase0aBattleOutcome.victory);
    expect(terminal.last, isA<Phase0aBattleVictory>());
    expect(tracker.progress.completed, isTrue);
    expect(source.frames.last.afterSpawn.removedCount, 2);
  });

  test('empty exhausted arena stays ongoing while objective is incomplete', () {
    final tracker = _tracker([
      ObjectiveClause(
        id: 'target',
        objective: DefeatTargetsObjective(const ['unreached-target']),
      ),
    ]);
    final source = _CallbackSource((frame) {
      return [
        for (final defeat
            in frame.combatEvents.whereType<Phase0aEnemyDefeated>())
          TargetDefeated('other-target', eventId: 'other:${defeat.seq}'),
      ];
    });
    final fixture = _Fixture(
      damage: 100,
      playerOnly: true,
      objectiveTracker: tracker,
      objectiveEventSource: source,
    );

    final events = fixture.flow.advance(deltaSeconds: 1, command: _attack);

    expect(fixture.flow.state.enemies, isEmpty);
    expect(fixture.flow.spawnState.pendingCount, 0);
    expect(fixture.flow.spawnState.warningCount, 0);
    expect(fixture.flow.spawnState.activeCount, 0);
    expect(fixture.flow.outcome, Phase0aBattleOutcome.ongoing);
    expect(events.whereType<Phase0aBattleVictory>(), isEmpty);
    expect(tracker.progress.completed, isFalse);
  });

  test('objective completion wins while enemies remain alive', () {
    final tracker = _tracker([
      ObjectiveClause(
        id: 'elapsed',
        objective: SurviveDurationObjective(const Duration(seconds: 1)),
      ),
    ]);
    final source = _CallbackSource(
      (frame) => [
        TimeElapsed(
          Duration(microseconds: (frame.deltaSeconds * 1000000).round()),
          eventId: 'elapsed:${frame.afterArena.tick}',
        ),
      ],
    );
    final fixture = _Fixture(
      objectiveTracker: tracker,
      objectiveEventSource: source,
    );

    final events = fixture.flow.advance(deltaSeconds: 1, command: _idle);

    expect(fixture.flow.state.enemies, isNotEmpty);
    expect(fixture.flow.spawnState.activeCount, 1);
    expect(tracker.progress.completed, isTrue);
    expect(fixture.flow.outcome, Phase0aBattleOutcome.victory);
    expect(events.last, isA<Phase0aBattleVictory>());
  });

  test('player death has priority and does not call or commit objective', () {
    final tracker = _tracker([
      ObjectiveClause(
        id: 'elapsed',
        objective: SurviveDurationObjective(const Duration(seconds: 1)),
      ),
    ]);
    final initialProgress = tracker.progress;
    final source = _CallbackSource(
      (_) => [
        TimeElapsed(const Duration(seconds: 1), eventId: 'would-complete'),
      ],
    );
    final fixture = _Fixture(
      damage: 100,
      attackGraceTicks: 0,
      objectiveTracker: tracker,
      objectiveEventSource: source,
    );

    final events = fixture.flow.advance(deltaSeconds: 1, command: _idle);

    expect(fixture.flow.state.player.isAlive, isFalse);
    expect(fixture.flow.outcome, Phase0aBattleOutcome.defeat);
    expect(events.last, isA<Phase0aBattleDefeat>());
    expect(events.whereType<Phase0aBattleVictory>(), isEmpty);
    expect(source.frames, isEmpty);
    expect(tracker.progress, same(initialProgress));
  });

  test('duplicate objective events are harmless across and within frames', () {
    final tracker = _tracker([
      ObjectiveClause(
        id: 'targets',
        objective: DefeatTargetsObjective(const ['target-1', 'target-2']),
      ),
    ]);
    final source = _CallbackSource((frame) {
      final defeatedIds = frame.combatEvents
          .whereType<Phase0aEnemyDefeated>()
          .map((event) => event.target)
          .toSet();
      return [
        TargetDefeated('target-1', eventId: 'stable-target-1'),
        TargetDefeated('target-1', eventId: 'stable-target-1'),
        if (defeatedIds.contains('enemy_2'))
          TargetDefeated('target-2', eventId: 'stable-target-2'),
      ];
    });
    final fixture = _Fixture(
      enemyCount: 2,
      damage: 100,
      playerOnly: true,
      objectiveTracker: tracker,
      objectiveEventSource: source,
    );

    fixture.flow.advance(deltaSeconds: 1, command: _attack);
    fixture.flow.advance(deltaSeconds: 1, command: _idle);
    fixture.flow.advance(deltaSeconds: 1, command: _attack);

    expect(fixture.flow.outcome, Phase0aBattleOutcome.victory);
    expect(tracker.progress.completed, isTrue);
    expect(tracker.progress.clauses.single.progress.processedEventIds, {
      'targetDefeated:stable-target-1',
      'targetDefeated:stable-target-2',
    });
  });

  test('terminal advance is a strict objective source no-op', () {
    final tracker = _tracker([
      ObjectiveClause(
        id: 'elapsed',
        objective: SurviveDurationObjective(const Duration(seconds: 1)),
      ),
    ]);
    final source = _CallbackSource(
      (frame) => [
        TimeElapsed(
          const Duration(seconds: 1),
          eventId: 'elapsed:${frame.afterArena.tick}',
        ),
      ],
    );
    final fixture = _Fixture(
      objectiveTracker: tracker,
      objectiveEventSource: source,
    );
    fixture.flow.advance(deltaSeconds: 1, command: _idle);
    final terminalProgress = tracker.progress;
    final terminalState = fixture.flow.state;
    final sourceCalls = source.frames.length;

    final events = fixture.flow.advance(deltaSeconds: 1, command: _idle);

    expect(events, isEmpty);
    expect(fixture.flow.state, same(terminalState));
    expect(source.frames, hasLength(sourceCalls));
    expect(tracker.progress, same(terminalProgress));
    expect(fixture.flow.lastOrderedEventRecords, isEmpty);
  });

  test('immediate source failure rolls back flow and objective progress', () {
    final tracker = _tracker([
      ObjectiveClause(
        id: 'elapsed',
        objective: SurviveDurationObjective(const Duration(seconds: 1)),
      ),
    ]);
    var shouldThrow = true;
    final source = _CallbackSource((frame) {
      if (shouldThrow) throw StateError('source failure');
      return [
        TimeElapsed(
          const Duration(seconds: 1),
          eventId: 'elapsed:${frame.afterArena.tick}',
        ),
      ];
    });
    final fixture = _Fixture(
      objectiveTracker: tracker,
      objectiveEventSource: source,
    );
    final state = fixture.flow.state;
    final spawnTick = fixture.flow.spawnState.tick;
    final outcome = fixture.flow.outcome;
    final records = fixture.flow.lastOrderedEventRecords;
    final progress = tracker.progress;

    expect(
      () => fixture.flow.advance(deltaSeconds: 1, command: _idle),
      throwsStateError,
    );
    expect(fixture.flow.state, same(state));
    expect(fixture.flow.spawnState.tick, spawnTick);
    expect(fixture.flow.outcome, outcome);
    expect(fixture.flow.lastOrderedEventRecords, same(records));
    expect(tracker.progress, same(progress));

    shouldThrow = false;
    fixture.flow.advance(deltaSeconds: 1, command: _idle);
    expect(fixture.flow.outcome, Phase0aBattleOutcome.victory);
    expect(tracker.progress.completed, isTrue);
  });

  test('lazy source failure after an event rolls back the whole tick', () {
    final tracker = _tracker([
      ObjectiveClause(
        id: 'elapsed',
        objective: SurviveDurationObjective(const Duration(seconds: 1)),
      ),
    ]);
    final source = _CallbackSource((frame) sync* {
      yield TimeElapsed(
        const Duration(seconds: 1),
        eventId: 'elapsed:${frame.afterArena.tick}',
      );
      throw StateError('lazy source failure');
    });
    final fixture = _Fixture(
      objectiveTracker: tracker,
      objectiveEventSource: source,
    );
    final state = fixture.flow.state;
    final progress = tracker.progress;
    final records = fixture.flow.lastOrderedEventRecords;

    expect(
      () => fixture.flow.advance(deltaSeconds: 1, command: _idle),
      throwsStateError,
    );
    expect(fixture.flow.state, same(state));
    expect(fixture.flow.spawnState.tick, 0);
    expect(fixture.flow.outcome, Phase0aBattleOutcome.ongoing);
    expect(fixture.flow.lastOrderedEventRecords, same(records));
    expect(tracker.progress, same(progress));
  });

  test('reachable spawn projection failure rolls back every owned state', () {
    final tracker = _tracker([
      ObjectiveClause(
        id: 'elapsed',
        objective: SurviveDurationObjective(const Duration(seconds: 1)),
      ),
    ]);
    final source = _CallbackSource(
      (_) => [
        TimeElapsed(const Duration(seconds: 1), eventId: 'would-complete'),
      ],
    );
    final fixture = _Fixture(
      nextSeq: -1,
      objectiveTracker: tracker,
      objectiveEventSource: source,
    );
    final state = fixture.flow.state;
    final records = fixture.flow.lastOrderedEventRecords;
    final progress = tracker.progress;

    expect(
      () => fixture.flow.advance(deltaSeconds: 1, command: _idle),
      throwsArgumentError,
    );
    expect(fixture.flow.state, same(state));
    expect(fixture.flow.spawnState.tick, 0);
    expect(fixture.flow.outcome, Phase0aBattleOutcome.ongoing);
    expect(fixture.flow.lastOrderedEventRecords, same(records));
    expect(tracker.progress, same(progress));
    expect(source.frames, isEmpty);
  });

  test('explicit null objective runtime preserves the omitted legacy path', () {
    final omitted = _Fixture(
      damage: 100,
      playerOnly: true,
      passObjectiveArguments: false,
    );
    final explicitNull = _Fixture(damage: 100, playerOnly: true);

    final omittedEvents = omitted.flow.advance(
      deltaSeconds: 1,
      command: _attack,
    );
    final explicitEvents = explicitNull.flow.advance(
      deltaSeconds: 1,
      command: _attack,
    );

    expect(explicitEvents, omittedEvents);
    expect(explicitNull.flow.state, omitted.flow.state);
    expect(explicitNull.flow.spawnState.tick, omitted.flow.spawnState.tick);
    expect(explicitNull.flow.outcome, omitted.flow.outcome);
    expect(
      explicitNull.flow.lastOrderedEventRecords,
      omitted.flow.lastOrderedEventRecords,
    );
    expect(explicitNull.flow.outcome, Phase0aBattleOutcome.victory);
  });

  test('configured objective ignores old surviveTicks victory', () {
    final tracker = _tracker([
      ObjectiveClause(
        id: 'target',
        objective: DefeatTargetsObjective(const ['unreached-target']),
      ),
    ]);
    final source = _CallbackSource((_) => const <EncounterObjectiveEvent>[]);
    final fixture = _Fixture(
      winCondition: const Phase0aWinCondition.surviveTicks(1),
      objectiveTracker: tracker,
      objectiveEventSource: source,
    );

    final events = fixture.flow.advance(deltaSeconds: 1, command: _idle);

    expect(fixture.flow.state.surviveTicksRemaining, 0);
    expect(fixture.flow.outcome, Phase0aBattleOutcome.ongoing);
    expect(events.whereType<Phase0aBattleVictory>(), isEmpty);
    expect(tracker.progress.completed, isFalse);
  });
}
