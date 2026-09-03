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
  'stage_08_01': ('ch8_encounter_01_frontier_riders', 12, 2),
  'stage_08_02': ('ch8_encounter_02_desert_skirmishers', 3, 2),
  'stage_08_03': ('ch8_encounter_03_grey_cloak_night', 1, 1),
  'stage_08_04': ('ch8_encounter_04_garrison_gate', 5, 1),
  'stage_08_05': ('ch8_encounter_05_grey_cloak_final', 1, 1),
};

const _narrativeActorIds = {
  'stage_08_01': {
    'ch8_s01_leader_01',
    'ch8_s01_blade_02',
    'ch8_s01_blade_03',
    'ch8_s01_charger_01',
    'ch8_s01_charger_02',
    'ch8_s01_charger_03',
    'ch8_s01_charger_04',
    'ch8_s01_charger_05',
    'ch8_s01_archer_01',
    'ch8_s01_archer_02',
    'ch8_s01_archer_03',
    'ch8_s01_archer_04',
  },
  'stage_08_02': {'ch8_s02_leader_01', 'ch8_s02_flank_01', 'ch8_s02_flank_02'},
  'stage_08_03': {'ch8_s03_grey_cloak'},
  'stage_08_04': {
    'ch8_s04_veteran_01',
    'ch8_s04_guard_01',
    'ch8_s04_guard_02',
    'ch8_s04_guard_03',
    'ch8_s04_guard_04',
  },
  'stage_08_05': {'ch8_s05_grey_cloak'},
};

const _bossCases = {
  'stage_08_03': ('ch8_encounter_03_grey_cloak_night', 'ch8_s03_grey_cloak'),
  'stage_08_05': ('ch8_encounter_05_grey_cloak_final', 'ch8_s05_grey_cloak'),
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

  test('Chapter 8 exposes five of five migrated production routes', () {
    final chapterStageIds = repository.stageDefs.values
        .where((stage) => stage.chapterIndex == 8)
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
    expect(migratedMainlineCount, greaterThanOrEqualTo(41));
  });

  test('Chapter 8 routes match the authored cast and runtime identities', () {
    for (final MapEntry(key: stageId, value: contract) in _expected.entries) {
      final stage = repository.getStage(stageId);
      final assignment = repository.combatAssignmentForStage(stageId);
      final encounter = repository.combatEncounterForStage(stageId);
      final runtime = repository.combatRuntimeBindingForStage(stageId);
      expect(assignment?.encounterId, contract.$1, reason: stageId);
      expect(encounter?.spawnEntries, hasLength(contract.$2), reason: stageId);
      expect(encounter?.spawnConfig.activeLimit, contract.$3, reason: stageId);
      expect(
        encounter?.spawnEntries.map((entry) => entry.entryId).toSet(),
        _narrativeActorIds[stageId],
        reason: '$stageId must match the authored narrative cast',
      );
      expect(runtime?.baseEnemyId, stage.enemyTeam.single.id, reason: stageId);
      expect(runtime?.enemyBindings, hasLength(contract.$2), reason: stageId);
    }
  });

  test('Chapter 8 routes construct through the real factory', () async {
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
      expect(host.tokenBindingsByActorId, hasLength(contract.$2));
    }
  });

  test('Chapter 8 objectives require every authored opponent', () {
    for (final stageId in ['stage_08_01', 'stage_08_02', 'stage_08_04']) {
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
      final progress = controller.advance(
        controller.initialProgress,
        CommanderDefeated(identity.$2),
      );
      expect(progress.completed, isTrue, reason: stageId);
    }
  });

  test('both authored Chapter 8 grey-cloak targets retain Boss identity', () {
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
      final target = bundle.actorBindingsByEntryId[identity.$2]!;
      expect(target.combatant.name, base.name, reason: stageId);
      expect(target.combatant.iconPath, base.iconPath, reason: stageId);
      expect(target.combatant.isBoss, isTrue, reason: stageId);
      expect(
        target.combatant.chargeSkillId,
        base.chargeSkillId,
        reason: stageId,
      );
      expect(
        target.combatant.availableSkills.map((skill) => skill.id),
        base.availableSkills.map((skill) => skill.id),
        reason: stageId,
      );
      expect(
        target.combatant.bossPhases
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
      expect(target.createActor('runtime-target').isBoss, isTrue);
    }
  });

  test(
    'all five Chapter 8 routes reach dynamic victory without stalls',
    () async {
      final source = _runtimeSource(repository);
      final maxTicks = repository.numbers.phase0aArena.maxSimulationTicks;
      final deltaSeconds = repository.numbers.phase0aArena.fixedDeltaSeconds;
      for (var index = 0; index < _expected.length; index++) {
        final stageId = _expected.keys.elementAt(index);
        final host = (await createFreshPhase0aMainlineEncounter(
          Phase0aMainlineEncounterHostBuildRequest(
            stage: repository.getStage(stageId),
            playerMapping: _playerMapping(repository, stageId),
            numbers: repository.numbers,
            cycleIndex: 1,
            rng: Random(2026090800 + index),
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
        expect(result.outcome, Phase0aBattleOutcome.victory, reason: stageId);
        expect(result.timedOut, isFalse, reason: stageId);
        expect(result.ticks, inInclusiveRange(1, maxTicks - 1));
        expect(
          result.events.whereType<Phase0aEnemyDefeated>(),
          hasLength(_expected[stageId]!.$2),
          reason: stageId,
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
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
  String stageId,
) => Phase0aStageContentMapper.mapPlayerOnly(
  contentId: stageId,
  playerSnapshot: testCombatantSnapshot(
    maxHp: 20000,
    currentHp: 20000,
    internalForce: 15000,
    totalEquipmentAttack: 2000,
    defenseRate: repository.numbers.cycleEvolution.defenseRateCap,
    includeProductionBasicAttack: true,
  ),
  numbers: repository.numbers,
);
