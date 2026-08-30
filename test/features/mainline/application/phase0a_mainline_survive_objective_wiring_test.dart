import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';

Phase0aActor _actor(String id, Phase0aSide side) => Phase0aActor(
  id: id,
  side: side,
  position: ArenaVector.zero,
  facing: const ArenaVector(1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

CombatEncounterDef _surviveEncounter() => CombatEncounterDef(
  id: 'survive_fixture',
  spawnConfig: CombatEncounterSpawnConfig(
    activeLimit: 1,
    reinforcementThreshold: 0,
    entryWarningTicks: 0,
    attackGraceTicks: 0,
  ),
  tokenBudgets: CombatEncounterTokenBudgets(
    melee: 1,
    ranged: 0,
    charge: 0,
    support: 0,
  ),
  spawnEntries: [
    CombatEncounterSpawnEntry(
      entryId: 'enemy_entry',
      archetypeId: 'fixture_archetype',
      roleId: 'fixture_role',
      entranceId: 'fixture_entrance',
      positionId: 'fixture_position',
      behaviorId: 'fixture_behavior',
    ),
  ],
  objectives: CombatObjectiveCompositionRef(
    completionRule: CombatObjectiveCompletionRule.all,
    clauses: [
      CombatObjectiveClauseRef(
        id: 'survive',
        primitive: CombatSurviveDurationRef(requiredTicks: 3),
      ),
    ],
  ),
);

void main() {
  test('typed survive objective projects exact frame time with stable id', () {
    final director = SpawnDirector(
      config: SpawnDirectorConfig(
        activeLimit: 1,
        reinforcementThreshold: 0,
        entryWarningTicks: 0,
        attackGraceTicks: 0,
      ),
      entries: [SpawnEntry(entryId: 'enemy_entry', enemyId: 'enemy')],
    );
    final roster = Phase0aEncounterRoster(
      director: director,
      playerId: 'player',
      bindings: [
        Phase0aEncounterRosterBinding(
          entryId: 'enemy_entry',
          actor: _actor('enemy', Phase0aSide.enemy),
        ),
      ],
    );
    final source = buildPhase0aMainlineObjectiveEventSource(
      encounter: _surviveEncounter(),
      roster: roster,
    );
    final before = Phase0aArenaState(
      tick: 6,
      nextSeq: 1,
      player: _actor('player', Phase0aSide.player),
      enemies: const [],
      skillSlots: const [],
    );
    final after = Phase0aArenaState(
      tick: 7,
      nextSeq: 1,
      player: _actor('player', Phase0aSide.player),
      enemies: const [],
      skillSlots: const [],
    );
    final frame = Phase0aEncounterObjectiveFrame(
      beforeArena: before,
      afterArena: after,
      beforeSpawn: director.state,
      afterSpawn: director.state,
      directorEvents: const [],
      spawnEvents: const [],
      combatEvents: const [],
      deltaSeconds: 0.125,
      playerMovementDelta: ArenaVector.zero,
    );

    final first = source.eventsFor(frame).toList(growable: false);
    final replayed = source.eventsFor(frame).toList(growable: false);

    expect(first, hasLength(1));
    expect(first.single, isA<TimeElapsed>());
    expect(
      (first.single as TimeElapsed).duration,
      const Duration(milliseconds: 125),
    );
    expect(replayed.single.id, first.single.id);
    expect(first.single.id, 'phase0a:survive:7');
  });
}
