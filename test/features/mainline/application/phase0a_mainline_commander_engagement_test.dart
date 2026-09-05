import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  setUpAll(() async => repository = await loadTestGameRepository());

  for (final stageId in [
    'stage_02_04',
    'stage_02_05',
    'stage_03_04',
    'stage_03_05',
    'stage_04_04',
    'stage_04_05',
    'stage_05_04',
  ]) {
    test(
      '$stageId source Boss engages a stationary player through production gates',
      () async {
        final stage = repository.getStage(stageId);
        final sourceBoss = stage.enemyTeam.single;
        final mapping = Phase0aStageContentMapper.mapPlayerOnly(
          contentId: stageId,
          // Observe enemy engagement at its own realm. No player attacks or
          // victory claims; the durable fixture only keeps the observer alive.
          playerSnapshot: testCombatantSnapshot(
            realmTier: sourceBoss.realmTier,
            realmLayer: sourceBoss.realmLayer,
            maxHp: 20000,
            currentHp: 20000,
            maxQi: 100,
            currentQi: 100,
            defenseRate: .8,
            includeProductionBasicAttack: true,
          ),
          numbers: repository.numbers,
        );
        final runtimeSource =
            Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
              loader:
                  ({
                    required String stageId,
                    required String encounterId,
                    required int cycleIndex,
                  }) => buildPhase0aMainlineRuntimeBindingBundleFromRepository(
                    stageId: stageId,
                    encounterId: encounterId,
                    cycleIndex: cycleIndex,
                    repository: repository,
                  ),
            );
        final host = (await createFreshPhase0aMainlineEncounter(
          Phase0aMainlineEncounterHostBuildRequest(
            stage: stage,
            playerMapping: mapping,
            numbers: repository.numbers,
            cycleIndex: 1,
            rng: Random(20260905),
            runtimeBindingSource: runtimeSource,
            catalogOverride: repository.combatCatalog,
          ),
        ))!;
        final bossInput = host.mapping!.combatants.singleWhere(
          (input) => input.snapshot.isBoss,
        );
        final bossId = bossInput.actorId;
        expect(bossInput.snapshot.enemyDefId, sourceBoss.id);
        expect(bossInput.snapshot.name, sourceBoss.name);
        expect(
          bossInput.snapshot.availableSkills.map((skill) => skill.id),
          containsAll(sourceBoss.skillIds),
        );
        expect(
          host.tokenBindingsByActorId![bossId]!.kind,
          AttackTokenKind.support,
        );
        final events = <Phase0aEvent>[];
        ArenaVector? initialPosition;
        for (var tick = 0; tick < 100; tick++) {
          events.addAll(
            host.advanceManual(
              deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
              command: const Phase0aPlayerCommand(),
            ),
          );
          for (final actor in host.flow.state.enemies) {
            if (actor.id == bossId) initialPosition ??= actor.position;
          }
        }
        expect(initialPosition, isNotNull);
        final boss = host.flow.state.enemies.singleWhere(
          (actor) => actor.id == bossId,
        );
        final player = host.flow.state.player;
        final initialDistance = (initialPosition! - player.position).length;
        final finalDistance = (boss.position - player.position).length;
        final starts = events
            .whereType<Phase0aAttackStarted>()
            .where((event) => event.actor == bossId)
            .length;
        final hits = events
            .whereType<Phase0aHitLanded>()
            .where(
              (event) =>
                  event.actor == bossId &&
                  event.target == player.id &&
                  event.resolvedDamage > 0,
            )
            .length;

        expect(player.position, mapping.initialPlayer.position);
        expect(
          initialDistance,
          greaterThan(host.mapping!.enemyAiAdapter.attackRange),
        );
        expect(finalDistance, lessThan(initialDistance));
        expect(starts, greaterThan(0));
        expect(hits, greaterThan(0));
      },
    );
  }
}
