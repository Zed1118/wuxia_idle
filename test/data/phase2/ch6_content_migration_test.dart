import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/validation/combat_objective_primitive_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';
import 'package:wuxia_idle/shared/battle_shared/enemy_combatant_snapshot_assembler.dart';

import '../../support/combatant_snapshot_fixture.dart';

Future<String> _fileLoader(String path) async =>
    (await File(path).readAsString()).replaceAll('\r\n', '\n');

const _expected = {
  'stage_06_01': ('ch6_encounter_01_lunjian_departure', 3, 3),
  'stage_06_02': ('ch6_encounter_02_songshan_return', 2, 2),
  'stage_06_03': ('ch6_encounter_03_yellow_river_source', 3, 3),
  'stage_06_04': ('ch6_encounter_04_kunlun_outer_gate', 3, 3),
  'stage_06_05': ('ch6_encounter_05_kunlun_summit', 3, 3),
};

const _narrativeActorIds = {
  'stage_06_02': {'ch6_s02_guard_01', 'ch6_s02_scout_01'},
};

const _bossCases = {
  'stage_06_04': (
    'ch6_encounter_04_kunlun_outer_gate',
    'ch6_s04_commander_01',
    ['ch6_s04_sword_guard_01', 'ch6_s04_evasive_guard_01'],
  ),
  'stage_06_05': (
    'ch6_encounter_05_kunlun_summit',
    'ch6_s05_commander_01',
    ['ch6_s05_gangmeng_01', 'ch6_s05_lingqiao_01'],
  ),
};

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

  test('Chapter 6 exposes five of five migrated production routes', () {
    final chapterStageIds = repository.stageDefs.values
        .where((stage) => stage.chapterIndex == 6)
        .map((stage) => stage.id)
        .toSet();
    expect(chapterStageIds, _expected.keys.toSet());
    for (final stageId in chapterStageIds) {
      expect(
        repository.combatAssignmentForStage(stageId)?.migrationState,
        CombatEncounterMigrationState.migrated,
        reason: stageId,
      );
      expect(repository.combatEncounterForStage(stageId), isNotNull);
      expect(repository.combatRuntimeBindingForStage(stageId), isNotNull);
    }
    final migratedMainlineCount = repository.combatCatalog!.stageAssignments
        .where(
          (assignment) =>
              assignment.migrationState ==
                  CombatEncounterMigrationState.migrated &&
              repository.stageDefs[assignment.stageId]?.stageType ==
                  StageType.mainline,
        )
        .length;
    expect(migratedMainlineCount, greaterThanOrEqualTo(33));
  });

  test('Chapter 6 routes close catalog and runtime identities', () {
    for (final MapEntry(key: stageId, value: contract) in _expected.entries) {
      final stage = repository.getStage(stageId);
      final assignment = repository.combatAssignmentForStage(stageId);
      final encounter = repository.combatEncounterForStage(stageId);
      final runtime = repository.combatRuntimeBindingForStage(stageId);
      expect(assignment?.encounterId, contract.$1, reason: stageId);
      expect(encounter?.spawnEntries, hasLength(contract.$2), reason: stageId);
      expect(encounter?.spawnConfig.activeLimit, contract.$3, reason: stageId);
      final expectedActorIds = _narrativeActorIds[stageId];
      if (expectedActorIds != null) {
        expect(
          encounter!.spawnEntries.map((entry) => entry.entryId).toSet(),
          expectedActorIds,
          reason: '$stageId must match the authored narrative cast',
        );
      }
      expect(runtime?.baseEnemyId, stage.enemyTeam.single.id, reason: stageId);
      expect(runtime?.enemyBindings, hasLength(contract.$2), reason: stageId);

      final bundle = buildPhase0aMainlineRuntimeBindingBundleFromRepository(
        stageId: stageId,
        encounterId: contract.$1,
        cycleIndex: 1,
        repository: repository,
      );
      expect(bundle.actorBindingsByEntryId, hasLength(contract.$2));
      expect(bundle.actorBindingsByEntryId.keys.toSet(), {
        for (final entry in encounter!.spawnEntries) entry.entryId,
      });

      final positions = <String>[];
      for (final entry in encounter.spawnEntries) {
        final point = runtime!.bindingForEntry(entry.entryId)!.position;
        positions.add('${point.x}:${point.y}');
      }
      expect(positions.toSet(), hasLength(contract.$3), reason: stageId);
    }
  });

  test('Chapter 6 routes construct through the real factory', () async {
    final source = _runtimeSource(repository);
    for (final MapEntry(key: stageId, value: contract) in _expected.entries) {
      final host = await createFreshPhase0aMainlineEncounter(
        Phase0aMainlineEncounterHostBuildRequest(
          stage: repository.getStage(stageId),
          playerMapping: _playerMapping(repository, stageId),
          numbers: repository.numbers,
          cycleIndex: 1,
          rng: Random(stageId.hashCode),
          runtimeBindingSource: source,
          catalogOverride: repository.combatCatalog,
        ),
      );
      expect(host, isNotNull, reason: stageId);
      expect(host!.mapping!.combatants, hasLength(contract.$2 + 1));
      expect(host.mapping!.director.config.activeLimit, contract.$3);
      expect(
        host.mapping!.enemyAiAdapter.behaviorProfilesByActor,
        hasLength(contract.$2),
      );
      expect(host.tokenBindingsByActorId, hasLength(contract.$2));
    }
  });

  test('Chapter 6 objectives require every authored opponent', () {
    for (final stageId in ['stage_06_01', 'stage_06_02', 'stage_06_03']) {
      final encounter = repository.combatEncounterForStage(stageId)!;
      final controller = mapCombatObjectiveComposition(
        encounter.objectives,
        tickDuration: const Duration(milliseconds: 100),
      );
      var progress = controller.initialProgress;
      for (var index = 0; index < encounter.spawnEntries.length; index++) {
        progress = controller.advance(
          progress,
          TargetDefeated(encounter.spawnEntries[index].entryId),
        );
        expect(progress.completed, index == encounter.spawnEntries.length - 1);
      }
    }

    for (final MapEntry(key: stageId, value: identity) in _bossCases.entries) {
      final encounter = repository.combatEncounterForStage(stageId)!;
      final controller = mapCombatObjectiveComposition(
        encounter.objectives,
        tickDuration: const Duration(milliseconds: 100),
      );
      var progress = controller.advance(
        controller.initialProgress,
        CommanderDefeated(identity.$2),
      );
      expect(progress.completed, isFalse, reason: identity.$1);
      for (var index = 0; index < identity.$3.length; index++) {
        progress = controller.advance(
          progress,
          TargetDefeated(identity.$3[index]),
        );
        expect(
          progress.completed,
          index == identity.$3.length - 1,
          reason: identity.$1,
        );
      }
    }
  });

  test('only authored Chapter 6 commanders retain Boss identity', () {
    for (final MapEntry(key: stageId, value: identity) in _bossCases.entries) {
      final base = EnemyCombatantSnapshotAssembler.assembleOne(
        enemy: repository.getStage(stageId).enemyTeam.single,
        slotIndex: 0,
        cycleIndex: 1,
        isTower: false,
      );
      final bundle = buildPhase0aMainlineRuntimeBindingBundleFromRepository(
        stageId: stageId,
        encounterId: identity.$1,
        cycleIndex: 1,
        repository: repository,
      );
      final commander = bundle.actorBindingsByEntryId[identity.$2]!;
      expect(commander.combatant.name, base.name, reason: stageId);
      expect(commander.combatant.iconPath, base.iconPath, reason: stageId);
      expect(commander.combatant.isBoss, isTrue, reason: stageId);
      expect(
        commander.combatant.chargeSkillId,
        base.chargeSkillId,
        reason: stageId,
      );
      expect(
        commander.combatant.bossPhases
            ?.map(
              (phase) => (
                phase.hpThresholdPct,
                phase.unlockSkillIds.join(','),
                phase.aiMode,
                phase.onEnterMechanic,
                phase.titleKey,
              ),
            )
            .toList(),
        base.bossPhases
            ?.map(
              (phase) => (
                phase.hpThresholdPct,
                phase.unlockSkillIds.join(','),
                phase.aiMode,
                phase.onEnterMechanic,
                phase.titleKey,
              ),
            )
            .toList(),
        reason: stageId,
      );
      expect(
        commander.combatant.availableSkills.map((skill) => skill.id),
        base.availableSkills.map((skill) => skill.id),
      );
      expect(commander.createActor('runtime-commander').isBoss, isTrue);

      for (final guardId in identity.$3) {
        final guard = bundle.actorBindingsByEntryId[guardId]!;
        expect(guard.combatant.isBoss, isFalse, reason: guardId);
        expect(guard.combatant.bossPhases, isNull, reason: guardId);
        expect(guard.combatant.chargeSkillId, isNull, reason: guardId);
        expect(guard.createActor('runtime-$guardId').isBoss, isFalse);
      }
    }
  });

  test(
    'all five Chapter 6 routes reach real dynamic victory without stalls',
    () async {
      final source = _runtimeSource(repository);
      final maxTicks = repository.numbers.phase0aArena.maxSimulationTicks;
      final deltaSeconds = repository.numbers.phase0aArena.fixedDeltaSeconds;
      for (var index = 0; index < _expected.length; index++) {
        final stageId = _expected.keys.elementAt(index);
        final host = (await createFreshPhase0aMainlineEncounter(
          Phase0aMainlineEncounterHostBuildRequest(
            stage: repository.getStage(stageId),
            playerMapping: _playerMapping(
              repository,
              stageId,
              useRedlineCeiling: true,
            ),
            numbers: repository.numbers,
            cycleIndex: 1,
            rng: Random(2026090600 + index),
            runtimeBindingSource: source,
            catalogOverride: repository.combatCatalog,
          ),
        ))!;
        final bot = Phase0aPlayerBotAdapter(
          playerAdapter: host.mapping!.playerAdapter,
          policy: const Phase0aBotTacticPolicy.assault(),
          objectiveContinuationCommandBuilder:
              host.objectiveContinuationCommandBuilder,
        );
        final result = host.runHeadless(
          bot: bot,
          deltaSeconds: deltaSeconds,
          maxTicks: maxTicks,
        );

        expect(
          result.outcome,
          Phase0aBattleOutcome.victory,
          reason: '$stageId outcome at tick ${result.ticks}',
        );
        expect(result.timedOut, isFalse, reason: stageId);
        expect(result.ticks, inInclusiveRange(1, maxTicks - 1));
        expect(result.finalState.player.isAlive, isTrue, reason: stageId);
        expect(
          result.events.whereType<Phase0aEnemyDefeated>(),
          hasLength(_expected[stageId]!.$2),
          reason: '$stageId must defeat every authored opponent',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Phase0aMainlineEncounterRuntimeBindingSource _runtimeSource(
  GameRepository repository,
) => Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
  loader: ({required stageId, required encounterId, required cycleIndex}) =>
      buildPhase0aMainlineRuntimeBindingBundleFromRepository(
        stageId: stageId,
        encounterId: encounterId,
        cycleIndex: cycleIndex,
        repository: repository,
      ),
);

Phase0aPlayerRuntimeMapping _playerMapping(
  GameRepository repository,
  String stageId, {
  bool useRedlineCeiling = false,
}) => Phase0aStageContentMapper.mapPlayerOnly(
  contentId: stageId,
  playerSnapshot: testCombatantSnapshot(
    maxHp: useRedlineCeiling ? 20000 : 10000,
    currentHp: useRedlineCeiling ? 20000 : 10000,
    internalForce: useRedlineCeiling ? 15000 : 1000,
    totalEquipmentAttack: useRedlineCeiling ? 2000 : 1000,
    defenseRate: useRedlineCeiling
        ? repository.numbers.cycleEvolution.defenseRateCap
        : 0.2,
    includeProductionBasicAttack: true,
  ),
  numbers: repository.numbers,
);
