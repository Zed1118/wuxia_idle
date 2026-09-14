import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_wave_battle_flow.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/enemy_combatant_snapshot_assembler.dart';

import '../support/isar_test_support.dart';
import '../support/phase0a_ch1_founder_profile.dart';
import '../support/phase0a_production_headless_benchmark.dart';

final _activityCases = [
  for (var stage = 1; stage <= 5; stage++)
    HeadlessBenchmarkContent.lightFoot('stage_light_foot_0$stage'),
  for (var stage = 1; stage <= 5; stage++)
    for (final formation in Formation.values)
      HeadlessBenchmarkContent.massBattle(
        'stage_mass_battle_0$stage',
        formation: formation,
      ),
];

void main() {
  late GameRepository repository;
  final profiles = <String, CombatantSnapshot>{};

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    for (final school in ['gang_meng', 'ling_qiao', 'yin_rou']) {
      final directory = await Directory.systemTemp.createTemp(
        'headless_activity_contract_',
      );
      try {
        await IsarSetup.init(directory: directory, inspector: false);
        final profile = await seedPhase0aCh1FounderProfile(
          isar: IsarSetup.instance,
          schoolId: school,
          originId: 'mountain_wanderer',
          fateId: 'balanced_seed',
          rngSeed: 20260820,
        );
        profiles[school] = profile.snapshot;
      } finally {
        await IsarSetup.close();
        IsarSetup.resetForTest();
        await directory.delete(recursive: true);
      }
    }
  });

  test(
    'formation distinguishes cases while preserving production content id',
    () {
      final variants = [
        for (final formation in Formation.values)
          HeadlessBenchmarkContent.massBattle(
            'stage_mass_battle_01',
            formation: formation,
          ),
      ];
      expect(variants.toSet(), hasLength(3));
      expect(variants.map((entry) => entry.contentId).toSet(), {
        'stage_mass_battle_01',
      });
      for (var index = 0; index < variants.length; index++) {
        final content = variants[index];
        final formation = Formation.values[index];
        expect(content.kind, HeadlessBenchmarkContentKind.massBattle);
        expect(content.formation, formation);
        expect(content.variant, formation.name);
        expect(
          content.caseId,
          'massBattle/stage_mass_battle_01/${formation.name}',
        );
        expect(
          content,
          HeadlessBenchmarkContent.massBattle(
            content.contentId,
            formation: formation,
          ),
        );
      }
      const lightFoot = HeadlessBenchmarkContent.lightFoot(
        'stage_light_foot_01',
      );
      expect(lightFoot.formation, isNull);
      expect(lightFoot.variant, 'default');
      expect(lightFoot.caseId, 'lightFoot/stage_light_foot_01/default');
    },
  );

  for (final content in _activityCases) {
    test(
      '${content.caseId} uses real inputs and preserves sync/async results',
      () async {
        final stage = repository.getStage(content.contentId);
        final isLightFoot =
            content.kind == HeadlessBenchmarkContentKind.lightFoot;
        final expectedRoute = isLightFoot
            ? 'legacy_light_foot'
            : 'legacy_mass_battle';
        for (final profile in profiles.entries) {
          final player = profile.value;
          final playerBefore = headlessPlayerFacts(player);
          final session = await createProductionHeadlessSession(
            repository: repository,
            content: content,
            player: player,
            seed: 73,
          );
          expect(session.route, expectedRoute, reason: profile.key);
          expect(session.flow, isA<Phase0aWaveBattleFlow>());
          final flow = session.flow as Phase0aWaveBattleFlow;
          final playerInput = session.combatants.singleWhere(
            (input) => input.actorId == flow.state.player.id,
          );
          final enemyInputs = session.combatants
              .where((input) => input.actorId != flow.state.player.id)
              .toList();
          final enemyActorIds = [
            for (final wave in flow.waves)
              for (final enemy in wave.enemies) enemy.id,
          ];
          expect(enemyActorIds.toSet(), hasLength(enemyActorIds.length));
          expect(enemyInputs.map((input) => input.actorId), enemyActorIds);
          final cap = repository.numbers.combat.redLines.combinedRateCap;

          if (isLightFoot) {
            expect(stage.stageType, StageType.lightFoot);
            final modifier = repository
                .numbers
                .lightFoot
                .terrainModifiers[stage.terrainBiome]!;
            final baseEnemies = EnemyCombatantSnapshotAssembler.assembleAll(
              stage.enemyTeam,
              cycleIndex: 1,
              isTower: false,
              advanceRealmPerCycle: true,
            );
            expect(flow.waves, hasLength(1));
            expect(enemyInputs, hasLength(stage.enemyTeam.length));
            expect(flow.waveTransitionPolicy, isNull);
            final sources = [player, ...baseEnemies];
            final actual = [
              playerInput.snapshot,
              ...enemyInputs.map((input) => input.snapshot),
            ];
            for (var index = 0; index < sources.length; index++) {
              _expectModifier(
                actual[index],
                sources[index],
                criticalDelta: modifier.criticalRateDelta,
                evasionDelta: modifier.evasionRateDelta,
                defenseDelta: modifier.defenseRateDelta,
                damageMultiplier: modifier.damageMultiplier,
                cap: cap,
                reason: '${profile.key}/${content.caseId}/actor=$index',
              );
            }
          } else {
            expect(stage.stageType, StageType.massBattle);
            final modifier =
                repository.numbers.massBattle.formations[content.formation]!;
            _expectModifier(
              playerInput.snapshot,
              player,
              criticalDelta: modifier.criticalRateDelta,
              evasionDelta: modifier.evasionRateDelta,
              defenseDelta: modifier.defenseRateDelta,
              damageMultiplier: modifier.damageMultiplier,
              cap: cap,
              reason: '${profile.key}/${content.caseId}/player',
            );
            final baseWaves = EnemyCombatantSnapshotAssembler.assembleWaves(
              stage,
              cycleIndex: 1,
            );
            final baseEnemies = baseWaves.expand((wave) => wave).toList();
            expect(
              flow.waves.map((wave) => wave.enemies.length),
              stage.massBattleEnemyCounts,
            );
            expect(enemyInputs, hasLength(baseEnemies.length));
            for (var index = 0; index < baseEnemies.length; index++) {
              expect(
                headlessPlayerFacts(enemyInputs[index].snapshot),
                headlessPlayerFacts(baseEnemies[index]),
                reason:
                    '${profile.key}/${content.caseId}/enemy=$index must not receive formation',
              );
            }
            final policy = flow.waveTransitionPolicy;
            expect(
              policy,
              isNotNull,
              reason:
                  'The actual running flow must own the intermission policy',
            );
            final config = repository.numbers.massBattle.waveIntermission;
            expect(policy!.healPlayerToFull, config.aliveHpRecoveryPct >= 1);
            expect(policy.qiRecoveryPct, config.aliveIfRecoveryPct);
            expect(policy.resetAttackCooldown, config.resetActionPoint);
            expect(policy.resetSkillCooldowns, !config.preserveCooldowns);
            expect(policy.intermissionSeconds, config.intermissionSeconds);
          }

          final sync = await measureProductionHeadless(
            repository: repository,
            content: content,
            player: player,
            seed: 73,
            mode: HeadlessBenchmarkMode.sync,
          );
          final async = await measureProductionHeadless(
            repository: repository,
            content: content,
            player: player,
            seed: 73,
            mode: HeadlessBenchmarkMode.async,
          );
          expect(sync.route, expectedRoute);
          expect(async.route, expectedRoute);
          requireSameHeadlessResult(sync, async);
          expect(sync.waveFacts, isNotNull);
          final waveFacts = jsonDecode(sync.waveFacts!) as Map;
          expect(waveFacts['started_wave_indices'], [
            for (final event
                in sync.result.events.whereType<Phase0aWaveStarted>())
              event.waveIndex,
          ]);
          expect(waveFacts['cleared_wave_indices'], [
            for (final event
                in sync.result.events.whereType<Phase0aWaveCleared>())
              event.waveIndex,
          ]);
          expect(waveFacts['waves'], [
            for (final wave in flow.waves)
              [for (final enemy in wave.enemies) enemy.id],
          ]);
          final actualPolicy = flow.waveTransitionPolicy;
          expect(
            waveFacts['transition_policy'],
            actualPolicy == null
                ? null
                : {
                    'heal_player_to_full': actualPolicy.healPlayerToFull,
                    'qi_recovery_pct': actualPolicy.qiRecoveryPct,
                    'reset_attack_cooldown': actualPolicy.resetAttackCooldown,
                    'reset_skill_cooldowns': actualPolicy.resetSkillCooldowns,
                    'intermission_seconds': actualPolicy.intermissionSeconds,
                  },
          );
          expect(sync.result.ticks, greaterThan(0));
          expect(sync.simulationMicroseconds, greaterThan(0));
          expect(async.simulationMicroseconds, greaterThan(0));
          expect(sync.settlement == null, sync.result.timedOut);
          expect(async.settlement == null, async.result.timedOut);
          expect(
            headlessPlayerFacts(player),
            playerBefore,
            reason: 'Fresh sessions must not mutate the founder input',
          );
        }
      },
    );
  }

  test(
    'wave facts cannot drift while arena, events and settlement agree',
    () async {
      final reference = await measureProductionHeadless(
        repository: repository,
        content: const HeadlessBenchmarkContent.massBattle(
          'stage_mass_battle_01',
          formation: Formation.baGua,
        ),
        player: profiles['gang_meng']!,
        seed: 73,
        mode: HeadlessBenchmarkMode.sync,
      );
      expect(reference.waveFacts, isNotNull);
      final changed = HeadlessBenchmarkRun(
        route: reference.route,
        mode: reference.mode,
        result: reference.result,
        settlement: reference.settlement,
        assemblyMicroseconds: reference.assemblyMicroseconds,
        simulationMicroseconds: reference.simulationMicroseconds,
        settlementMicroseconds: reference.settlementMicroseconds,
        encounterFacts: reference.encounterFacts,
        waveFacts: '{}',
      );
      expect(
        () => requireSameHeadlessResult(reference, changed),
        throwsStateError,
      );
    },
  );
}

void _expectModifier(
  CombatantSnapshot actual,
  CombatantSnapshot base, {
  required double criticalDelta,
  required double evasionDelta,
  required double defenseDelta,
  required double damageMultiplier,
  required double cap,
  required String reason,
}) {
  final expected = headlessPlayerFacts(base);
  expected['critical_rate'] = (base.criticalRate + criticalDelta).clamp(
    0.0,
    cap,
  );
  expected['evasion_rate'] = (base.evasionRate + evasionDelta).clamp(0.0, cap);
  expected['defense_rate'] = (base.defenseRate + defenseDelta).clamp(0.0, cap);
  expected['attack_power_multiplier'] = damageMultiplier;
  expect(headlessPlayerFacts(actual), expected, reason: reason);
}
