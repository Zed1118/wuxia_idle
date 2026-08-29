import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_explicit_objective_event_source.dart';
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
import 'package:wuxia_idle/features/battle/domain/phase0a/status_effects.dart';

Phase0aActor _actor(
  String id, {
  required Phase0aSide side,
  int health = 100,
  Phase0aDefeatKind defeatKind = Phase0aDefeatKind.normal,
  ArenaVector position = ArenaVector.zero,
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
  defeatKind: defeatKind,
);

final class _EncounterFixture {
  _EncounterFixture({
    Map<String, String> entries = const {
      'entry_role_commander': 'runtime_actor_alpha',
      'entry_role_target': 'runtime_actor_beta',
    },
  }) {
    director = SpawnDirector(
      config: SpawnDirectorConfig(
        activeLimit: entries.length,
        reinforcementThreshold: 0,
        entryWarningTicks: 0,
        attackGraceTicks: 0,
      ),
      entries: [
        for (final entry in entries.entries)
          SpawnEntry(entryId: entry.key, enemyId: entry.value),
      ],
    );
    roster = Phase0aEncounterRoster(
      director: director,
      playerId: 'player',
      bindings: [
        for (final entry in entries.entries)
          Phase0aEncounterRosterBinding(
            entryId: entry.key,
            actor: _actor(entry.value, side: Phase0aSide.enemy),
          ),
      ],
    );
  }

  late final SpawnDirector director;
  late final Phase0aEncounterRoster roster;

  Phase0aEncounterObjectiveFrame frame({
    Iterable<Phase0aEvent> combatEvents = const [],
  }) => Phase0aEncounterObjectiveFrame(
    beforeArena: Phase0aArenaState(
      tick: 0,
      nextSeq: 0,
      player: _actor('player', side: Phase0aSide.player),
      enemies: const [],
      skillSlots: const [],
    ),
    afterArena: Phase0aArenaState(
      tick: 1,
      nextSeq: 0,
      player: _actor('player', side: Phase0aSide.player),
      enemies: const [],
      skillSlots: const [],
    ),
    beforeSpawn: director.state,
    afterSpawn: director.state,
    directorEvents: const [],
    spawnEvents: const [],
    combatEvents: combatEvents,
    deltaSeconds: 1,
    playerMovementDelta: ArenaVector.zero,
  );
}

Phase0aEnemyDefeated _defeated(
  String target, {
  required int tick,
  required int seq,
  Phase0aDefeatKind defeatKind = Phase0aDefeatKind.normal,
  ArenaVector? targetPosition,
}) => Phase0aEnemyDefeated(
  seq: seq,
  tick: tick,
  target: target,
  defeatKind: defeatKind,
  targetPosition: targetPosition,
);

Phase0aExplicitObjectiveEventSource _source(
  _EncounterFixture fixture, {
  Map<String, Iterable<Phase0aDefeatObjectiveProjection>>? projections,
  Iterable<Phase0aExternalObjectiveEventProjector> externalProjectors =
      const [],
}) => Phase0aExplicitObjectiveEventSource(
  roster: fixture.roster,
  defeatProjectionsByActorId:
      projections ??
      const {
        'runtime_actor_alpha': <Phase0aDefeatObjectiveProjection>[],
        'runtime_actor_beta': <Phase0aDefeatObjectiveProjection>[],
      },
  externalProjectors: externalProjectors,
);

void main() {
  test('objective frame keeps an immutable actor status snapshot', () {
    final fixture = _EncounterFixture();
    final ledger = TimedStatusLedger.empty
      ..apply(
        TimedStatusSpec(
          type: TimedStatusType.poison,
          sourceId: 'runtime_actor_alpha',
          durationTicks: 3,
          tickIntervalTicks: 1,
          stackLimit: 1,
          damagePerTick: 5,
        ),
      );
    final beforeStatus = ledger.snapshot;
    final frame = Phase0aEncounterObjectiveFrame(
      beforeArena: Phase0aArenaState(
        tick: 0,
        nextSeq: 0,
        player: _actor(
          'player',
          side: Phase0aSide.player,
        ).copyWith(statusLedger: beforeStatus),
        enemies: const [],
        skillSlots: const [],
      ),
      afterArena: Phase0aArenaState(
        tick: 1,
        nextSeq: 0,
        player: _actor('player', side: Phase0aSide.player),
        enemies: const [],
        skillSlots: const [],
      ),
      beforeSpawn: fixture.director.state,
      afterSpawn: fixture.director.state,
      directorEvents: const [],
      spawnEvents: const [],
      combatEvents: const [],
      deltaSeconds: 0.1,
      playerMovementDelta: ArenaVector.zero,
    );

    ledger.advance(1);

    expect(frame.beforeArena.player.statusLedger, beforeStatus);
    expect(
      frame.beforeArena.player.statusLedger.instances.single.remainingTicks,
      3,
    );
  });

  test('constructor requires exact roster actor coverage', () {
    final fixture = _EncounterFixture();

    expect(
      () => _source(
        fixture,
        projections: const {
          'runtime_actor_alpha': <Phase0aDefeatObjectiveProjection>[],
        },
      ),
      throwsArgumentError,
    );
    expect(
      () => _source(
        fixture,
        projections: const {
          'runtime_actor_alpha': <Phase0aDefeatObjectiveProjection>[],
          'runtime_actor_beta': <Phase0aDefeatObjectiveProjection>[],
          'runtime_actor_extra': <Phase0aDefeatObjectiveProjection>[],
        },
      ),
      throwsArgumentError,
    );
  });

  test('explicit empty projection is a strict defeat no-op', () {
    final fixture = _EncounterFixture();
    final source = _source(fixture);

    final events = source.eventsFor(
      fixture.frame(
        combatEvents: [_defeated('runtime_actor_alpha', tick: 3, seq: 7)],
      ),
    );

    expect(events, isEmpty);
    expect(events, isA<List<EncounterObjectiveEvent>>());
    expect(() => events.clear(), throwsUnsupportedError);
  });

  test(
    'target and commander payloads are explicit and declaration ordered',
    () {
      final fixture = _EncounterFixture();
      final source = _source(
        fixture,
        projections: const {
          'runtime_actor_alpha': [
            Phase0aTargetDefeatProjection('objective_target_explicit'),
            Phase0aCommanderDefeatProjection('objective_commander_explicit'),
          ],
          'runtime_actor_beta': <Phase0aDefeatObjectiveProjection>[],
        },
      );

      final events = source.eventsFor(
        fixture.frame(
          combatEvents: [_defeated('runtime_actor_alpha', tick: 4, seq: 12)],
        ),
      );

      expect(events, hasLength(2));
      expect(events[0], isA<TargetDefeated>());
      expect(
        (events[0] as TargetDefeated).targetId,
        'objective_target_explicit',
      );
      expect(events[0].id, 'phase0a:defeat:4:12:0');
      expect(events[1], isA<CommanderDefeated>());
      expect(
        (events[1] as CommanderDefeated).commanderId,
        'objective_commander_explicit',
      );
      expect(events[1].id, 'phase0a:defeat:4:12:1');
    },
  );

  test('combat order then per-actor declaration order is globally stable', () {
    final fixture = _EncounterFixture();
    final source = _source(
      fixture,
      projections: const {
        'runtime_actor_alpha': [
          Phase0aTargetDefeatProjection('target_alpha_1'),
          Phase0aTargetDefeatProjection('target_alpha_2'),
        ],
        'runtime_actor_beta': [
          Phase0aCommanderDefeatProjection('commander_beta'),
        ],
      },
    );
    final frame = fixture.frame(
      combatEvents: [
        _defeated('runtime_actor_beta', tick: 8, seq: 20),
        _defeated('runtime_actor_alpha', tick: 8, seq: 23),
      ],
    );

    final first = source.eventsFor(frame);
    final replay = source.eventsFor(frame);

    expect(first.map((event) => event.id), [
      'phase0a:defeat:8:20:0',
      'phase0a:defeat:8:23:0',
      'phase0a:defeat:8:23:1',
    ]);
    expect(first.map((event) => event.dedupeKey), [
      'commanderDefeated:phase0a:defeat:8:20:0',
      'targetDefeated:phase0a:defeat:8:23:0',
      'targetDefeated:phase0a:defeat:8:23:1',
    ]);
    expect(
      replay.map((event) => event.dedupeKey),
      first.map((e) => e.dedupeKey),
    );
  });

  test('unknown defeated runtime actor fails closed', () {
    final fixture = _EncounterFixture();
    final source = _source(fixture);

    expect(
      () => source.eventsFor(
        fixture.frame(
          combatEvents: [_defeated('runtime_actor_unknown', tick: 1, seq: 1)],
        ),
      ),
      throwsArgumentError,
    );
  });

  test('entry wording defeat kind and position cannot change projection', () {
    final fixture = _EncounterFixture(
      entries: const {
        'entry_commander_elite_role': 'runtime_target_named_commander',
      },
    );
    final source = _source(
      fixture,
      projections: const {
        'runtime_target_named_commander': [
          Phase0aTargetDefeatProjection('explicit_target_only'),
        ],
      },
    );

    List<EncounterObjectiveEvent> project(
      Phase0aDefeatKind kind,
      ArenaVector position,
    ) => source.eventsFor(
      fixture.frame(
        combatEvents: [
          _defeated(
            'runtime_target_named_commander',
            tick: 2,
            seq: 5,
            defeatKind: kind,
            targetPosition: position,
          ),
        ],
      ),
    );

    final normal = project(Phase0aDefeatKind.normal, ArenaVector.zero);
    final elite = project(Phase0aDefeatKind.elite, const ArenaVector(999, 999));
    expect(normal.single, isA<TargetDefeated>());
    expect(elite.single, isA<TargetDefeated>());
    expect(normal.single.id, elite.single.id);
    expect((elite.single as TargetDefeated).targetId, 'explicit_target_only');
  });

  test('non-defeat combat events do not consult defeat projections', () {
    final fixture = _EncounterFixture();
    final source = _source(fixture);

    final events = source.eventsFor(
      fixture.frame(
        combatEvents: const [
          Phase0aAttackStarted(
            seq: 1,
            tick: 1,
            actor: 'runtime_actor_unknown',
            moveKind: Phase0aMoveKind.light,
          ),
        ],
      ),
    );

    expect(events, isEmpty);
  });

  test('external six kinds append in projector and yield order', () {
    final fixture = _EncounterFixture();
    final calls = <String>[];
    final source = _source(
      fixture,
      externalProjectors: [
        (frame) sync* {
          calls.add('first:start');
          yield AnchorDestroyed('anchor', eventId: 'external:anchor');
          calls.add('first:end');
          yield EntityDefended(
            'entity',
            const Duration(seconds: 1),
            eventId: 'external:defend',
          );
          yield TimeElapsed(
            const Duration(seconds: 1),
            eventId: 'external:time',
          );
        },
        (frame) sync* {
          calls.add('second:start');
          yield CheckpointReached('checkpoint', eventId: 'external:checkpoint');
          yield MarkerTouched('marker', eventId: 'external:marker');
          yield TargetPursued('pursued', eventId: 'external:pursue');
          calls.add('second:end');
        },
      ],
    );

    final events = source.eventsFor(fixture.frame());

    expect(calls, ['first:start', 'first:end', 'second:start', 'second:end']);
    expect(events.map((event) => event.runtimeType), [
      AnchorDestroyed,
      EntityDefended,
      TimeElapsed,
      CheckpointReached,
      MarkerTouched,
      TargetPursued,
    ]);
  });

  test('defeat projections precede all external projections', () {
    final fixture = _EncounterFixture();
    final source = _source(
      fixture,
      projections: const {
        'runtime_actor_alpha': [Phase0aTargetDefeatProjection('target_alpha')],
        'runtime_actor_beta': <Phase0aDefeatObjectiveProjection>[],
      },
      externalProjectors: [
        (_) => [MarkerTouched('marker', eventId: 'external:marker')],
      ],
    );

    final events = source.eventsFor(
      fixture.frame(
        combatEvents: [_defeated('runtime_actor_alpha', tick: 1, seq: 2)],
      ),
    );

    expect(events.map((event) => event.runtimeType), [
      TargetDefeated,
      MarkerTouched,
    ]);
  });

  test('external projectors cannot bypass defeat actor coverage', () {
    final fixture = _EncounterFixture();

    for (final event in <EncounterObjectiveEvent>[
      TargetDefeated('forbidden', eventId: 'forbidden:target'),
      CommanderDefeated('forbidden', eventId: 'forbidden:commander'),
    ]) {
      final source = _source(
        fixture,
        externalProjectors: [
          (_) => [event],
        ],
      );
      expect(() => source.eventsFor(fixture.frame()), throwsArgumentError);
    }
  });

  test('lazy projector batch is fully materialized before return', () {
    final fixture = _EncounterFixture();
    var yields = 0;
    final source = _source(
      fixture,
      externalProjectors: [
        (_) sync* {
          yields++;
          yield MarkerTouched('first', eventId: 'external:first');
          yields++;
          yield MarkerTouched('second', eventId: 'external:second');
        },
      ],
    );

    final events = source.eventsFor(fixture.frame());

    expect(yields, 2);
    expect(events, hasLength(2));
    expect(events, isA<List<EncounterObjectiveEvent>>());
  });

  test('lazy projector failure exposes no partial return value', () {
    final fixture = _EncounterFixture();
    var yields = 0;
    List<EncounterObjectiveEvent>? returned;
    final source = _source(
      fixture,
      externalProjectors: [
        (_) sync* {
          yields++;
          yield MarkerTouched('partial', eventId: 'external:partial');
          throw StateError('lazy projector failed');
        },
      ],
    );

    expect(
      () => returned = source.eventsFor(fixture.frame()),
      throwsStateError,
    );
    expect(yields, 1);
    expect(returned, isNull);
  });

  test('constructor snapshots caller map lists and projector iterable', () {
    final fixture = _EncounterFixture();
    final alpha = <Phase0aDefeatObjectiveProjection>[
      const Phase0aTargetDefeatProjection('original_target'),
    ];
    final beta = <Phase0aDefeatObjectiveProjection>[];
    final projections = <String, Iterable<Phase0aDefeatObjectiveProjection>>{
      'runtime_actor_alpha': alpha,
      'runtime_actor_beta': beta,
    };
    final projectorCalls = <String>[];
    final projectors = <Phase0aExternalObjectiveEventProjector>[
      (_) {
        projectorCalls.add('original');
        return const <EncounterObjectiveEvent>[];
      },
    ];
    final source = _source(
      fixture,
      projections: projections,
      externalProjectors: projectors,
    );

    alpha
      ..clear()
      ..add(const Phase0aCommanderDefeatProjection('replacement_commander'));
    projections
      ..clear()
      ..['runtime_actor_extra'] = const [];
    projectors
      ..clear()
      ..add((_) {
        projectorCalls.add('replacement');
        return const <EncounterObjectiveEvent>[];
      });

    final events = source.eventsFor(
      fixture.frame(
        combatEvents: [_defeated('runtime_actor_alpha', tick: 1, seq: 9)],
      ),
    );
    expect(events.single, isA<TargetDefeated>());
    expect((events.single as TargetDefeated).targetId, 'original_target');
    expect(projectorCalls, ['original']);
  });

  test('R09 flow rolls back every owned state on source lazy failure', () {
    final fixture = _EncounterFixture(
      entries: const {'entry_enemy': 'runtime_actor_alpha'},
    );
    final tracker = Phase0aObjectiveRuntimeTracker(
      controller: ObjectiveController(
        completionRule: ObjectiveCompletionRule.all,
        clauses: [
          ObjectiveClause(
            id: 'survive',
            objective: SurviveDurationObjective(const Duration(seconds: 1)),
          ),
        ],
      ),
    );
    final source = _source(
      fixture,
      projections: const {
        'runtime_actor_alpha': <Phase0aDefeatObjectiveProjection>[],
      },
      externalProjectors: [
        (_) sync* {
          yield TimeElapsed(
            const Duration(seconds: 1),
            eventId: 'external:would_complete',
          );
          throw StateError('source failed after yield');
        },
      ],
    );
    final initialState = Phase0aArenaState(
      tick: 0,
      nextSeq: 0,
      player: _actor('player', side: Phase0aSide.player),
      enemies: const [],
      skillSlots: const [],
    );
    final flow = Phase0aEncounterFlow.runtime(
      session: Phase0aCombatSession(
        initialState: initialState,
        playerAdapter: _playerAdapter,
        enemyAiAdapter: _enemyAdapter,
        damageResolver: const _ZeroResolver(),
      ),
      director: fixture.director,
      roster: fixture.roster,
      objectiveTracker: tracker,
      objectiveEventSource: source,
    );
    final initialProgress = tracker.progress;
    final initialRecords = flow.lastOrderedEventRecords;

    expect(
      () =>
          flow.advance(deltaSeconds: 1, command: const Phase0aPlayerCommand()),
      throwsStateError,
    );
    expect(flow.state, same(initialState));
    expect(flow.spawnState.tick, 0);
    expect(flow.outcome, Phase0aBattleOutcome.ongoing);
    expect(flow.lastOrderedEventRecords, same(initialRecords));
    expect(tracker.progress, same(initialProgress));
  });

  test('source remains explicit and isolated from semantic inference', () {
    final source = File(
      'lib/features/battle/application/phase0a/'
      'phase0a_explicit_objective_event_source.dart',
    ).readAsStringSync();
    final imports = RegExp(
      r"^import '([^']+)';$",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)).toList();

    expect(imports, [
      '../../domain/phase0a/encounter_enemy_roster.dart',
      '../../domain/phase0a/encounter_objective.dart',
      '../../domain/phase0a/phase0a_combat_events.dart',
      'phase0a_encounter_objective_event_source.dart',
    ]);
    for (final forbidden in <String>[
      'bindingByEntryId',
      '.entryId',
      '.defeatKind',
      '.targetPosition',
      '.roleId',
      'archetype',
      'candidate_',
      'GameRepository',
      'dart:io',
      '.startsWith(',
      ".contains('commander')",
      ".contains('target')",
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
  });
}

const _playerAdapter = Phase0aPlayerInputAdapter(
  playerId: 'player',
  attackRange: 1,
  attackHalfArcRadians: 1,
  attackCooldownSeconds: 1,
  attackQiDelta: 0,
  postureBasicPowerMultiplier: 1,
  attackPowerMultiplier: 1,
  gatherPowerMultiplier: 1,
  clearPowerMultiplier: 1,
  gatherSlot: 'gather',
  gatherRingRadius: 1,
  gatherEffectRadius: 1,
  gatherQiCost: 0,
  gatherCooldownSeconds: 1,
  clearSlot: 'clear',
  clearEffectRadius: 1,
  clearQiCost: 0,
  clearCooldownSeconds: 1,
);

const _enemyAdapter = Phase0aEnemyAiAdapter(
  attackRange: 1,
  attackHalfArcRadians: 1,
  attackCooldownSeconds: 1,
  postureBasicPowerMultiplier: 1,
  uniformBasicPowerMultiplier: 1,
);

final class _ZeroResolver implements Phase0aDamageResolver {
  const _ZeroResolver();

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    required double defenderWardMult,
  }) => const Phase0aResolvedHit(isHit: false, isCritical: false, damage: 0);
}
