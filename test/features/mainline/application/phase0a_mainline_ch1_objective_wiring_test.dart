import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_explicit_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';

Future<String> _fileLoader(String path) async =>
    (await File(path).readAsString()).replaceAll('\r\n', '\n');

Phase0aActor _player(double x) => Phase0aActor(
  id: 'player',
  side: Phase0aSide.player,
  position: ArenaVector(x, 0),
  facing: const ArenaVector(1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 1,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

final class _ObjectiveFixture {
  _ObjectiveFixture(GameRepository repository, this.stageId)
    : encounter = repository.combatEncounterForStage(stageId)! {
    final bundle = buildPhase0aMainlineRuntimeBindingBundleFromRepository(
      stageId: stageId,
      encounterId: encounter.id,
      cycleIndex: 1,
      repository: repository,
    );
    director = SpawnDirector(
      config: SpawnDirectorConfig(
        activeLimit: encounter.spawnConfig.activeLimit,
        reinforcementThreshold: encounter.spawnConfig.reinforcementThreshold,
        entryWarningTicks: encounter.spawnConfig.entryWarningTicks,
        attackGraceTicks: encounter.spawnConfig.attackGraceTicks,
      ),
      entries: [
        for (var index = 0; index < encounter.spawnEntries.length; index++)
          SpawnEntry(
            entryId: encounter.spawnEntries[index].entryId,
            enemyId: 'runtime-$index',
          ),
      ],
    );
    roster = Phase0aEncounterRoster(
      director: director,
      playerId: 'player',
      bindings: [
        for (var index = 0; index < encounter.spawnEntries.length; index++)
          Phase0aEncounterRosterBinding(
            entryId: encounter.spawnEntries[index].entryId,
            actor: bundle
                .actorBindingsByEntryId[encounter.spawnEntries[index].entryId]!
                .createActor('runtime-$index'),
          ),
      ],
    );
    source = buildPhase0aMainlineObjectiveEventSource(
      encounter: encounter,
      roster: roster,
    );
  }

  final String stageId;
  final CombatEncounterDef encounter;
  late final SpawnDirector director;
  late final Phase0aEncounterRoster roster;
  late final Phase0aExplicitObjectiveEventSource source;

  String actorId(String entryId) => roster.bindingByEntryId(entryId)!.actorId;

  List<EncounterObjectiveEvent> events({
    List<Phase0aEvent> combatEvents = const [],
    double beforeX = 0,
    double afterX = 0,
  }) => source
      .eventsFor(
        Phase0aEncounterObjectiveFrame(
          beforeArena: Phase0aArenaState(
            tick: 10,
            nextSeq: 1,
            player: _player(beforeX),
            enemies: const [],
            skillSlots: const [],
          ),
          afterArena: Phase0aArenaState(
            tick: 11,
            nextSeq: 1,
            player: _player(afterX),
            enemies: const [],
            skillSlots: const [],
          ),
          beforeSpawn: director.state,
          afterSpawn: director.state,
          directorEvents: const [],
          spawnEvents: const [],
          combatEvents: combatEvents,
          deltaSeconds: 0.1,
        ),
      )
      .cast<EncounterObjectiveEvent>()
      .toList(growable: false);

  List<EncounterObjectiveEvent> defeat(String entryId) => events(
    combatEvents: [
      Phase0aEnemyDefeated(
        seq: 7,
        tick: 11,
        target: actorId(entryId),
        defeatKind: Phase0aDefeatKind.normal,
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameRepository repository;

  setUpAll(() async {
    repository = await GameRepository.loadAllDefs(
      loader: _fileLoader,
      assetExists: (path) async => File(path).existsSync(),
    );
  });
  tearDownAll(GameRepository.resetForTest);

  test('stage 1 checkpoint emits only on the approved x=520 crossing', () {
    final fixture = _ObjectiveFixture(repository, 'stage_01_01');

    final crossed = fixture.events(beforeX: 519, afterX: 520);
    expect(crossed, hasLength(1));
    expect(
      (crossed.single as CheckpointReached).checkpointId,
      'ch1_s01_checkpoint_exit',
    );
    expect(fixture.events(beforeX: 520, afterX: 521), isEmpty);
    expect(fixture.events(beforeX: 519, afterX: 519.9), isEmpty);
  });

  test(
    'stage 2 anchors come only from exact gate and roof defeat entrances',
    () {
      final fixture = _ObjectiveFixture(repository, 'stage_01_02');
      String firstAt(String entranceId) => fixture.encounter.spawnEntries
          .firstWhere((entry) => entry.entranceId == entranceId)
          .entryId;

      expect(
        (fixture.defeat(firstAt('ch1_entrance_s02_gate')).single
                as AnchorDestroyed)
            .anchorId,
        'ch1_s02_anchor_gate',
      );
      expect(
        (fixture.defeat(firstAt('ch1_entrance_s02_roof')).single
                as AnchorDestroyed)
            .anchorId,
        'ch1_s02_anchor_gong_rack',
      );
      final leader = fixture.defeat('ch1_s02_leader_01');
      expect(leader, hasLength(1));
      expect(
        (leader.single as CommanderDefeated).commanderId,
        'ch1_s02_leader_01',
        reason: 'gong role and yard entrance must not infer an anchor event',
      );
    },
  );

  test(
    'commander and target events follow typed refs without role inference',
    () {
      final stage4 = _ObjectiveFixture(repository, 'stage_01_04');
      expect(
        stage4.defeat('ch1_s04_leader_01').single,
        isA<CommanderDefeated>(),
      );
      expect(stage4.defeat('ch1_s04_blade_01').single, isA<TargetDefeated>());
      expect(stage4.defeat('ch1_s04_rope_01').single, isA<TargetDefeated>());

      final stage5 = _ObjectiveFixture(repository, 'stage_01_05');
      expect(
        stage5.defeat('ch1_s05_leader_01').single,
        isA<CommanderDefeated>(),
      );
      expect(
        stage5.defeat('ch1_s05_blade_01'),
        isEmpty,
        reason:
            'a guard has no defeat projection unless the typed objective says so',
      );
    },
  );
}
