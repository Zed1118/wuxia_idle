import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_host.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_enemy_behavior_profile.dart';
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

  for (final stageId in ['stage_01_04', 'stage_01_05']) {
    test('$stageId closes distance and attacks a stationary player', () async {
      final host = await _host(repository, stageId);
      final mapping = host.mapping!;
      final bossId = mapping.combatants
          .singleWhere((input) => input.snapshot.isBoss)
          .actorId;
      final source = repository.getStage(stageId).enemyTeam.single;
      final bossSnapshot = mapping.combatants
          .singleWhere((input) => input.actorId == bossId)
          .snapshot;
      expect(bossSnapshot.enemyDefId, source.id);
      expect(bossSnapshot.name, source.name);
      expect(bossSnapshot.iconPath, source.iconPath);
      expect(
        bossSnapshot.availableSkills.map((skill) => skill.id),
        containsAll(source.skillIds),
      );
      expect(
        host.tokenBindingsByActorId![bossId]!.kind,
        AttackTokenKind.support,
      );

      final events = <Phase0aEvent>[];
      ArenaVector? initialBossPosition;
      for (var tick = 0; tick < 100; tick++) {
        events.addAll(
          host.advanceManual(
            deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
            command: const Phase0aPlayerCommand(),
          ),
        );
        for (final actor in host.flow.state.enemies) {
          if (actor.id == bossId) initialBossPosition ??= actor.position;
        }
      }
      final boss = host.flow.state.enemies.singleWhere(
        (actor) => actor.id == bossId,
      );
      final player = host.flow.state.player;
      expect(player.position, mapping.initialState.player.position);
      expect(initialBossPosition, isNotNull);
      final initialDistance = (initialBossPosition! - player.position).length;
      expect(initialDistance, greaterThan(mapping.enemyAiAdapter.attackRange));
      expect(
        (boss.position - player.position).length,
        lessThan(initialDistance),
      );
      expect(
        events.whereType<Phase0aAttackStarted>().where(
          (event) => event.actor == bossId,
        ),
        isNotEmpty,
      );
      expect(
        events.whereType<Phase0aHitLanded>().where(
          (event) =>
              event.actor == bossId &&
              event.target == player.id &&
              event.resolvedDamage > 0,
        ),
        isNotEmpty,
      );
      if (stageId == 'stage_01_05') {
        expect(
          events.whereType<Phase0aBossChargeStarted>().where(
            (event) => event.actor == bossId,
          ),
          isNotEmpty,
        );
        expect(
          events.whereType<Phase0aEnemySkillStarted>().where(
            (event) =>
                event.actor == bossId &&
                event.skillId == 'skill_xie_yu_chuan_lian',
          ),
          isNotEmpty,
        );
      }
    });

    test(
      '$stageId still attacks after the player walks into close range',
      () async {
        final host = await _host(repository, stageId);
        final bossId = host.mapping!.combatants
            .singleWhere((input) => input.snapshot.isBoss)
            .actorId;
        final events = <Phase0aEvent>[];
        for (var tick = 0; tick < 100; tick++) {
          events.addAll(
            host.advanceManual(
              deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
              command: Phase0aPlayerCommand(right: tick < 13),
            ),
          );
        }
        expect(
          events.whereType<Phase0aAttackStarted>().where(
            (event) => event.actor == bossId,
          ),
          isNotEmpty,
        );
        expect(
          events.whereType<Phase0aHitLanded>().where(
            (event) =>
                event.actor == bossId &&
                event.target == host.flow.state.player.id &&
                event.resolvedDamage > 0,
          ),
          isNotEmpty,
        );
      },
    );
  }

  test(
    'ordinary Blackwind gong support still holds its assigned position',
    () async {
      const stageId = 'stage_01_03';
      final host = await _host(repository, stageId);
      final encounter = repository.combatEncounterForStage(stageId)!;
      final bindings = buildPhase0aMainlineRuntimeBindingBundleFromRepository(
        stageId: stageId,
        encounterId: encounter.id,
        cycleIndex: 1,
        repository: repository,
      );
      final ordinal = encounter.spawnEntries.indexWhere(
        (entry) => entry.entryId == 'ch1_s03_leader_01',
      );
      final actorId =
          '$stageId/${encounter.id}/actor-${ordinal.toString().padLeft(3, '0')}';
      final binding = bindings.actorBindingsByEntryId['ch1_s03_leader_01']!;
      final actor = binding.createActor(actorId);
      expect(actor.isBoss, isFalse);
      expect(binding.token.kind, AttackTokenKind.support);
      expect(
        binding.behaviorProfile!.movementPolicy,
        Phase0aEnemyMovementPolicy.guardedPosition,
      );
      final state = Phase0aArenaState(
        tick: 0,
        nextSeq: 1,
        player: host.mapping!.initialState.player.copyWith(
          position: actor.position + const ArenaVector(-300, 0),
        ),
        enemies: [actor],
        skillSlots: host.mapping!.initialState.skillSlots,
      );
      final intent = host.mapping!.enemyAiAdapter
          .intentsFor(state: state)
          .single;
      expect(intent, isA<Phase0aMoveIntent>());
      expect((intent as Phase0aMoveIntent).direction, ArenaVector.zero);
    },
  );
}

Future<Phase0aEncounterHost> _host(
  GameRepository repository,
  String stageId,
) async {
  // Durable observation fixture; this test verifies enemy engagement, not
  // starter difficulty, player victory, or human acceptance.
  final player = Phase0aStageContentMapper.mapPlayerOnly(
    contentId: stageId,
    playerSnapshot: testCombatantSnapshot(
      maxHp: 20000,
      currentHp: 20000,
      maxQi: 100,
      currentQi: 100,
      includeProductionBasicAttack: true,
    ),
    numbers: repository.numbers,
  );
  final source = Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
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
  return (await createFreshPhase0aMainlineEncounter(
    Phase0aMainlineEncounterHostBuildRequest(
      stage: repository.getStage(stageId),
      playerMapping: player,
      numbers: repository.numbers,
      cycleIndex: 1,
      rng: Random(20260905),
      runtimeBindingSource: source,
      catalogOverride: repository.combatCatalog,
    ),
  ))!;
}
