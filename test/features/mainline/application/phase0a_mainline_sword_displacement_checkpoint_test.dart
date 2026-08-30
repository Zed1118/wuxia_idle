import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_host.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_runtime_observation.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  Future<Phase0aEncounterHost> fresh({double initialX = 500}) async {
    final base = Phase0aStageContentMapper.mapPlayerOnly(
      contentId: 'stage_01_01',
      playerSnapshot: testCombatantSnapshot(
        maxHp: 20000,
        currentHp: 20000,
        includeProductionBasicAttack: true,
      ),
      numbers: repository.numbers,
    );
    final playerMapping = Phase0aPlayerRuntimeMapping(
      snapshot: base.snapshot,
      initialPlayer: base.initialPlayer.copyWith(
        position: ArenaVector(initialX, 0),
        basicAttackSegmentIndex: 2,
      ),
      skillSlots: base.skillSlots,
      moveBindings: base.moveBindings,
      playerAdapter: base.playerAdapter,
      defenseTuning: base.defenseTuning,
    );
    final source = Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
      loader:
          ({
            required String stageId,
            required String encounterId,
            required int cycleIndex,
          }) async => buildPhase0aMainlineRuntimeBindingBundleFromRepository(
            stageId: stageId,
            encounterId: encounterId,
            cycleIndex: cycleIndex,
            repository: repository,
          ),
    );
    return (await createFreshPhase0aMainlineEncounter(
      Phase0aMainlineEncounterHostBuildRequest(
        stage: repository.getStage('stage_01_01'),
        playerMapping: playerMapping,
        numbers: repository.numbers,
        cycleIndex: 1,
        rng: Random(20260829),
        runtimeBindingSource: source,
        catalogOverride: repository.combatCatalog,
      ),
    ))!;
  }

  bool checkpointCompleted(Phase0aEncounterHost host) {
    final observation = (host.flow as Phase0aEncounterRuntimeObservationSource)
        .runtimeObservation;
    return observation.objectiveProgress!.clauses
        .singleWhere((clause) => clause.id == 'ch1_s01_reach_exit')
        .completed;
  }

  test(
    'single ranged attack never moves or triggers x=520 checkpoint, movement still can',
    () async {
      final attackHost = await fresh();
      final attackEvents = attackHost.advanceManual(
        deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
        command: const Phase0aPlayerCommand(
          attack: true,
          attackAimDirection: ArenaVector(1, 0),
        ),
      );
      expect(
        attackEvents
            .whereType<Phase0aAttackStarted>()
            .singleWhere((event) => event.actor == 'player')
            .basicAttackSegment,
        isNull,
      );
      expect(attackHost.flow.state.player.position.x, 500);
      expect(attackHost.flow.outcome, Phase0aBattleOutcome.ongoing);
      expect(checkpointCompleted(attackHost), isFalse);

      final mixedHost = await fresh(initialX: 490);
      mixedHost.advanceManual(
        deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
        command: const Phase0aPlayerCommand(
          right: true,
          attack: true,
          attackAimDirection: ArenaVector(1, 0),
        ),
      );
      expect(mixedHost.flow.state.player.position.x, 511);
      expect(
        490 +
            repository.numbers.phase0aArena.playerMoveSpeed *
                repository.numbers.phase0aArena.fixedDeltaSeconds,
        lessThan(520),
        reason: 'normal movement alone must remain before the checkpoint',
      );
      expect(
        checkpointCompleted(mixedHost),
        isFalse,
        reason: 'single ranged attack must not add displacement to the frame',
      );

      final movementHost = await fresh();
      movementHost.advanceManual(
        deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
        command: const Phase0aPlayerCommand(right: true),
      );
      expect(
        movementHost.flow.state.player.position.x,
        greaterThanOrEqualTo(520),
      );
      expect(checkpointCompleted(movementHost), isTrue);
      expect(
        movementHost.flow.outcome,
        Phase0aBattleOutcome.ongoing,
        reason: 'the separate clear-road clause is intentionally unfinished',
      );
    },
  );
}
