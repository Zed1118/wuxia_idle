import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/validation/combat_encounter_defeat_projection_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_explicit_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';

CombatEncounterSpawnEntry _entry(String id) => CombatEncounterSpawnEntry(
  entryId: id,
  archetypeId: 'archetype_$id',
  roleId: 'role_$id',
  entranceId: 'entrance_$id',
  positionId: 'position_$id',
  behaviorId: 'behavior_$id',
);

CombatEncounterDef _definition({
  List<String> entryIds = const ['entry_alpha', 'entry_beta'],
  List<CombatObjectivePrimitiveRef>? primitives,
}) => CombatEncounterDef(
  id: 'encounter_projection',
  spawnConfig: CombatEncounterSpawnConfig(
    activeLimit: entryIds.length,
    reinforcementThreshold: 0,
    entryWarningTicks: 1,
    attackGraceTicks: 1,
  ),
  tokenBudgets: CombatEncounterTokenBudgets(
    melee: 1,
    ranged: 1,
    charge: 1,
    support: 1,
  ),
  spawnEntries: entryIds.map(_entry),
  objectives: CombatObjectiveCompositionRef(
    completionRule: CombatObjectiveCompletionRule.all,
    clauses: [
      for (
        var index = 0;
        index < (primitives ?? _defeatPrimitives).length;
        index += 1
      )
        CombatObjectiveClauseRef(
          id: 'clause_$index',
          primitive: (primitives ?? _defeatPrimitives)[index],
        ),
    ],
  ),
);

final List<CombatObjectivePrimitiveRef> _defeatPrimitives = [
  CombatDefeatTargetsRef(const ['objective_same', 'objective_target']),
  CombatDefeatCommanderRef(commanderId: 'objective_same'),
];

Phase0aActor _actor(String id) => Phase0aActor(
  id: id,
  side: Phase0aSide.enemy,
  position: const ArenaVector(4, 7),
  facing: const ArenaVector(-1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

final class _Fixture {
  _Fixture({
    Map<String, String> entries = const {
      'entry_alpha': 'runtime_actor_zeta',
      'entry_beta': 'runtime_actor_eta',
    },
  }) {
    director = SpawnDirector(
      config: SpawnDirectorConfig(
        activeLimit: entries.length,
        reinforcementThreshold: 0,
        entryWarningTicks: 1,
        attackGraceTicks: 1,
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
            actor: _actor(entry.value),
          ),
      ],
    );
  }

  late final SpawnDirector director;
  late final Phase0aEncounterRoster roster;

  Phase0aEncounterObjectiveFrame frame(String actorId) =>
      Phase0aEncounterObjectiveFrame(
        beforeArena: const Phase0aArenaState(
          tick: 0,
          nextSeq: 0,
          player: Phase0aActor(
            id: 'player',
            side: Phase0aSide.player,
            position: ArenaVector.zero,
            facing: ArenaVector(1, 0),
            maxHealth: 100,
            currentHealth: 100,
            moveSpeed: 1,
            qiCurrent: 0,
            qiMax: 100,
            attackCooldownRemaining: 0,
            defeatKind: Phase0aDefeatKind.normal,
          ),
          enemies: [],
          skillSlots: [],
        ),
        afterArena: const Phase0aArenaState(
          tick: 1,
          nextSeq: 0,
          player: Phase0aActor(
            id: 'player',
            side: Phase0aSide.player,
            position: ArenaVector.zero,
            facing: ArenaVector(1, 0),
            maxHealth: 100,
            currentHealth: 100,
            moveSpeed: 1,
            qiCurrent: 0,
            qiMax: 100,
            attackCooldownRemaining: 0,
            defeatKind: Phase0aDefeatKind.normal,
          ),
          enemies: [],
          skillSlots: [],
        ),
        beforeSpawn: director.state,
        afterSpawn: director.state,
        directorEvents: const [],
        spawnEvents: const [],
        combatEvents: [
          Phase0aEnemyDefeated(
            seq: 3,
            tick: 9,
            target: actorId,
            defeatKind: Phase0aDefeatKind.normal,
          ),
        ],
        deltaSeconds: 1,
      );
}

List<MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>>
_validDeclarations() => const [
  MapEntry('entry_alpha', [
    Phase0aCommanderDefeatProjection('objective_same'),
    Phase0aTargetDefeatProjection('objective_same'),
  ]),
  MapEntry('entry_beta', [Phase0aTargetDefeatProjection('objective_target')]),
];

void main() {
  test(
    'maps payloads by exact entry binding and preserves declaration order',
    () {
      final fixture = _Fixture();
      final source = mapCombatEncounterDefeatObjectiveEventSource(
        _definition(),
        fixture.roster,
        defeatProjectionEntries: _validDeclarations(),
      );

      final events = source.eventsFor(fixture.frame('runtime_actor_zeta'));
      expect(events, hasLength(2));
      expect((events[0] as CommanderDefeated).commanderId, 'objective_same');
      expect((events[1] as TargetDefeated).targetId, 'objective_same');
    },
  );

  test(
    'definition and roster require exact entry cover including replacement',
    () {
      for (final entries in [
        const {'entry_alpha': 'runtime_actor_zeta'},
        const {
          'entry_alpha': 'runtime_actor_zeta',
          'entry_gamma': 'runtime_actor_eta',
        },
      ]) {
        expect(
          () => mapCombatEncounterDefeatObjectiveEventSource(
            _definition(),
            _Fixture(entries: entries).roster,
            defeatProjectionEntries: _validDeclarations(),
          ),
          throwsArgumentError,
        );
      }
    },
  );

  test(
    'declarations require exact entry cover and reject duplicate entries',
    () {
      final fixture = _Fixture();
      final invalid = [
        const [
          MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
            'entry_alpha',
            [],
          ),
        ],
        const [
          MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
            'entry_alpha',
            [],
          ),
          MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
            'entry_gamma',
            [],
          ),
        ],
        const [
          MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
            'entry_alpha',
            [],
          ),
          MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
            'entry_alpha',
            [],
          ),
          MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
            'entry_beta',
            [],
          ),
        ],
      ];
      for (final declarations in invalid) {
        expect(
          () => mapCombatEncounterDefeatObjectiveEventSource(
            _definition(),
            fixture.roster,
            defeatProjectionEntries: declarations,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => mapCombatEncounterDefeatObjectiveEventSource(
          _definition(
            primitives: [
              CombatDefeatTargetsRef(const ['objective_same']),
            ],
          ),
          fixture.roster,
          defeatProjectionEntries: const [
            MapEntry('entry_alpha', [
              Phase0aCommanderDefeatProjection('objective_same'),
            ]),
            MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
              'entry_beta',
              [],
            ),
          ],
        ),
        throwsArgumentError,
        reason: 'the same payload text cannot cross the typed kind boundary',
      );
    },
  );

  test(
    'typed objective closure rejects missing foreign and wrong-kind payloads',
    () {
      final fixture = _Fixture();
      final invalid = [
        const [
          MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
            'entry_alpha',
            [Phase0aCommanderDefeatProjection('objective_same')],
          ),
          MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
            'entry_beta',
            [Phase0aTargetDefeatProjection('objective_target')],
          ),
        ],
        const [
          MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
            'entry_alpha',
            [
              Phase0aCommanderDefeatProjection('objective_same'),
              Phase0aTargetDefeatProjection('objective_same'),
            ],
          ),
          MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
            'entry_beta',
            [Phase0aTargetDefeatProjection('foreign')],
          ),
        ],
        const [
          MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
            'entry_alpha',
            [
              Phase0aTargetDefeatProjection('objective_same'),
              Phase0aTargetDefeatProjection('objective_target'),
            ],
          ),
          MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
            'entry_beta',
            [Phase0aTargetDefeatProjection('objective_same')],
          ),
        ],
      ];
      for (final declarations in invalid) {
        expect(
          () => mapCombatEncounterDefeatObjectiveEventSource(
            _definition(),
            fixture.roster,
            defeatProjectionEntries: declarations,
          ),
          throwsArgumentError,
        );
      }
    },
  );

  test('duplicate typed payload fails within one entry or across entries', () {
    final fixture = _Fixture();
    for (final declarations in [
      const [
        MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
          'entry_alpha',
          [
            Phase0aTargetDefeatProjection('objective_same'),
            Phase0aTargetDefeatProjection('objective_same'),
            Phase0aCommanderDefeatProjection('objective_same'),
          ],
        ),
        MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
          'entry_beta',
          [Phase0aTargetDefeatProjection('objective_target')],
        ),
      ],
      const [
        MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
          'entry_alpha',
          [
            Phase0aTargetDefeatProjection('objective_same'),
            Phase0aCommanderDefeatProjection('objective_same'),
          ],
        ),
        MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
          'entry_beta',
          [
            Phase0aTargetDefeatProjection('objective_same'),
            Phase0aTargetDefeatProjection('objective_target'),
          ],
        ),
      ],
    ]) {
      expect(
        () => mapCombatEncounterDefeatObjectiveEventSource(
          _definition(),
          fixture.roster,
          defeatProjectionEntries: declarations,
        ),
        throwsArgumentError,
      );
    }
  });

  test(
    'repeated objective refs dedupe while target and commander stay distinct',
    () {
      final fixture = _Fixture();
      final definition = _definition(
        primitives: [
          CombatDefeatTargetsRef(const ['same']),
          CombatSurviveDurationRef(requiredTicks: 10),
          CombatDefeatTargetsRef(const ['same']),
          CombatDefeatCommanderRef(commanderId: 'same'),
        ],
      );

      expect(
        () => mapCombatEncounterDefeatObjectiveEventSource(
          definition,
          fixture.roster,
          defeatProjectionEntries: const [
            MapEntry('entry_alpha', [
              Phase0aTargetDefeatProjection('same'),
              Phase0aCommanderDefeatProjection('same'),
            ]),
            MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
              'entry_beta',
              [],
            ),
          ],
        ),
        returnsNormally,
      );
    },
  );

  test(
    'non-defeat objectives are ignored and defeat-free requires empty lists',
    () {
      final fixture = _Fixture();
      final definition = _definition(
        primitives: [CombatSurviveDurationRef(requiredTicks: 10)],
      );
      expect(
        () => mapCombatEncounterDefeatObjectiveEventSource(
          definition,
          fixture.roster,
          defeatProjectionEntries: const [
            MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
              'entry_alpha',
              [],
            ),
            MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
              'entry_beta',
              [],
            ),
          ],
        ),
        returnsNormally,
      );
      expect(
        () => mapCombatEncounterDefeatObjectiveEventSource(
          definition,
          fixture.roster,
          defeatProjectionEntries: const [
            MapEntry('entry_alpha', [Phase0aTargetDefeatProjection('foreign')]),
            MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>(
              'entry_beta',
              [],
            ),
          ],
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'caller iterables are materialized once and detached from later mutation',
    () {
      final fixture = _Fixture();
      var outerReads = 0;
      var innerReads = 0;
      final mutable = <Phase0aDefeatObjectiveProjection>[
        const Phase0aCommanderDefeatProjection('objective_same'),
        const Phase0aTargetDefeatProjection('objective_same'),
      ];
      Iterable<Phase0aDefeatObjectiveProjection> inner() sync* {
        innerReads++;
        yield* mutable;
      }

      Iterable<MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>>
      outer() sync* {
        outerReads++;
        yield MapEntry('entry_alpha', inner());
        yield const MapEntry('entry_beta', [
          Phase0aTargetDefeatProjection('objective_target'),
        ]);
      }

      final source = mapCombatEncounterDefeatObjectiveEventSource(
        _definition(),
        fixture.roster,
        defeatProjectionEntries: outer(),
      );
      mutable.clear();

      expect(outerReads, 1);
      expect(innerReads, 1);
      expect(
        source.eventsFor(fixture.frame('runtime_actor_zeta')),
        hasLength(2),
      );
    },
  );

  test('source guard keeps mapper pure and binding explicit', () {
    final source = File(
      'lib/data/validation/combat_encounter_defeat_projection_mapper.dart',
    ).readAsStringSync();
    final imports = RegExp(
      r"^import [\s\S]*?;",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(0)).toList();

    expect(imports, hasLength(3));
    expect(source, contains('bindingByEntryId'));
    expect(source, contains('externalProjectors: const []'));
    for (final forbidden in [
      'bindingByEnemyId',
      'entryPositionOf',
      '.archetypeId',
      '.roleId',
      '.entranceId',
      '.positionId',
      '.behaviorId',
      '.defeatKind',
      'startsWith(',
      'endsWith(',
      'contains(',
      'GameRepository',
      "dart:io",
      'SpawnDirector',
      'Phase0aActor',
      "'Phase0aTargetDefeatProjection('",
      "'Phase0aCommanderDefeatProjection('",
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
