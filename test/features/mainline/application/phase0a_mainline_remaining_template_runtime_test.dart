import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_host.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_pursue_objective_observation.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_survive_objective_observation.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_enemy_behavior_profile.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';

import '../../../support/combatant_snapshot_fixture.dart';

Future<String> _fileLoader(String path) async =>
    (await File(path).readAsString()).replaceAll('\r\n', '\n');

Phase0aMainlineEncounterRuntimeBindingSource _runtimeSource(
  GameRepository repository,
) => Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
  loader:
      ({required stageId, required encounterId, required cycleIndex}) async =>
          buildPhase0aMainlineRuntimeBindingBundleFromRepository(
            stageId: stageId,
            encounterId: encounterId,
            cycleIndex: cycleIndex,
            repository: repository,
          ),
);

Future<Phase0aEncounterHost> _host(
  GameRepository repository,
  String stageId, {
  int maxHp = 15000,
  int attack = 130,
  double defense = 0.05,
}) async {
  final playerMapping = Phase0aStageContentMapper.mapPlayerOnly(
    contentId: stageId,
    playerSnapshot: testCombatantSnapshot(
      maxHp: maxHp,
      currentHp: maxHp,
      totalEquipmentAttack: attack,
      defenseRate: defense,
      includeProductionBasicAttack: true,
    ),
    numbers: repository.numbers,
  );
  return (await createFreshPhase0aMainlineEncounter(
    Phase0aMainlineEncounterHostBuildRequest(
      stage: repository.getStage(stageId),
      playerMapping: playerMapping,
      numbers: repository.numbers,
      cycleIndex: 1,
      rng: Random(20260831),
      runtimeBindingSource: _runtimeSource(repository),
      catalogOverride: repository.combatCatalog,
    ),
  ))!;
}

Phase0aArenaState _arena({
  required int tick,
  required Phase0aActor player,
  required List<Phase0aActor> enemies,
}) => Phase0aArenaState(
  tick: tick,
  nextSeq: 1,
  player: player,
  enemies: enemies,
  skillSlots: const [],
);

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

  test(
    'production survive stage exposes 900 ticks and wins on the same core',
    () async {
      final host = await _host(
        repository,
        'stage_02_02',
        maxHp: 20000,
        attack: 2000,
        defense: 0.8,
      );
      final flow = host.flow as Phase0aSurviveObjectiveObservationSource;

      expect(
        flow.surviveObjectiveObservation?.requiredDuration,
        const Duration(seconds: 90),
      );

      final result = host.runHeadless(
        bot: Phase0aPlayerBotAdapter(
          playerAdapter: host.mapping!.playerAdapter,
        ),
        deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
        maxTicks: 901,
      );

      expect(result.outcome, Phase0aBattleOutcome.victory);
      expect(result.ticks, 900);
      expect(result.finalState.player.isAlive, isTrue);
    },
  );

  test(
    'production pursuit uses one moving boss actor and exact proximity',
    () async {
      final host = await _host(repository, 'stage_07_04');
      final encounter = repository.combatEncounterForStage('stage_07_04')!;
      final mapping = host.mapping!;
      const targetEntryId = 'ch7_s04_grey_cloak';
      final targetBinding = mapping.roster.bindingByEntryId(targetEntryId)!;
      final target = targetBinding.actor;

      expect(target.isBoss, isTrue);
      expect(
        mapping
            .enemyAiAdapter
            .behaviorProfilesByActor[targetBinding.actorId]
            ?.movementPolicy,
        Phase0aEnemyMovementPolicy.pursuitEvasion,
      );
      final observationSource =
          host.flow as Phase0aPursueObjectiveObservationSource;
      expect(
        observationSource.pursueObjectiveObservation?.targetId,
        targetEntryId,
      );
      expect(
        observationSource.pursueObjectiveObservation?.targetActorId,
        targetBinding.actorId,
      );
      expect(observationSource.pursueObjectiveObservation?.distance, isNull);

      final player = mapping.initialState.player;
      final farPlayer = player.copyWith(position: const ArenaVector(-320, 120));
      final closePlayer = player.copyWith(
        position: const ArenaVector(300, 120),
      );
      final movedTarget = target.copyWith(
        position: const ArenaVector(380, 120),
      );
      final source = buildPhase0aMainlineObjectiveEventSource(
        encounter: encounter,
        roster: mapping.roster,
        pursuitCaptureRange: repository.numbers.phase0aArena.playerAttackRange,
      );

      List<EncounterObjectiveEvent> eventsFor(Phase0aActor framePlayer) =>
          source
              .eventsFor(
                Phase0aEncounterObjectiveFrame(
                  beforeArena: _arena(
                    tick: 10,
                    player: framePlayer,
                    enemies: [movedTarget],
                  ),
                  afterArena: _arena(
                    tick: 11,
                    player: framePlayer,
                    enemies: [movedTarget],
                  ),
                  beforeSpawn: mapping.director.state,
                  afterSpawn: mapping.director.state,
                  directorEvents: const [],
                  spawnEvents: const [],
                  combatEvents: const [],
                  deltaSeconds:
                      repository.numbers.phase0aArena.fixedDeltaSeconds,
                  playerMovementDelta: ArenaVector.zero,
                ),
              )
              .toList(growable: false);

      expect(eventsFor(farPlayer), isEmpty);
      final caught = eventsFor(closePlayer);
      expect(caught, hasLength(1));
      expect(caught.single, isA<TargetPursued>());
      expect((caught.single as TargetPursued).targetId, targetEntryId);

      final intents = mapping.enemyAiAdapter.intentsFor(
        state: _arena(tick: 1, player: farPlayer, enemies: [target]),
      );
      final targetMove = intents.whereType<Phase0aMoveIntent>().singleWhere(
        (intent) => intent.actorId == targetBinding.actorId,
      );
      expect(targetMove.direction.x, greaterThan(0));

      final headless = await _host(
        repository,
        'stage_07_04',
        maxHp: 20000,
        attack: 2000,
        defense: 0.8,
      );
      final result = headless.runHeadless(
        bot: Phase0aPlayerBotAdapter(
          playerAdapter: headless.mapping!.playerAdapter,
        ),
        deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
        maxTicks: repository.numbers.phase0aArena.maxSimulationTicks,
      );
      expect(result.outcome, Phase0aBattleOutcome.victory);
      expect(result.finalState.player.isAlive, isTrue);
      final finalTarget = result.finalState.enemies.firstWhere(
        (enemy) => enemy.id == targetBinding.actorId,
      );
      expect((finalTarget.position - target.position).length, greaterThan(0));
    },
  );
}
