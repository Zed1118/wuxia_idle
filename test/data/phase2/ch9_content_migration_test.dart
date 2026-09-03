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
  'stage_09_01': ('ch9_encounter_01_pass_bandits', 4, 3),
  'stage_09_02': ('ch9_encounter_02_bone_dunes', 3, 3),
  'stage_09_03': ('ch9_encounter_03_mirage', 1, 1),
  'stage_09_04': ('ch9_encounter_04_cliff_guardian', 1, 1),
  'stage_09_05': ('ch9_encounter_05_old_master', 1, 1),
};

const _narrativeActorIds = {
  'stage_09_01': {
    'ch9_s01_leader_01',
    'ch9_s01_companion_01',
    'ch9_s01_companion_02',
    'ch9_s01_companion_03',
  },
  'stage_09_02': {'ch9_s02_leader_01', 'ch9_s02_flank_01', 'ch9_s02_flank_02'},
  'stage_09_03': {'ch9_s03_mirage'},
  'stage_09_04': {'ch9_s04_gatekeeper'},
  'stage_09_05': {'ch9_s05_old_master'},
};

const _bossCases = {
  'stage_09_04': ('ch9_encounter_04_cliff_guardian', 'ch9_s04_gatekeeper'),
  'stage_09_05': ('ch9_encounter_05_old_master', 'ch9_s05_old_master'),
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

  test('Chapter 9 exposes five of five migrated production routes', () {
    final chapterStageIds = repository.stageDefs.values
        .where((stage) => stage.chapterIndex == 9)
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
    expect(migratedMainlineCount, greaterThanOrEqualTo(46));
  });

  test('Chapter 9 routes match the authored cast and runtime identities', () {
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

    final duneEncounter = repository.combatEncounterForStage('stage_09_02')!;
    expect(duneEncounter.spawnConfig.activeLimit, 3);
    expect(duneEncounter.spawnConfig.attackGraceTicks, 30);
    expect(duneEncounter.tokenBudgets.melee, 1);

    final mirageBundle = buildPhase0aMainlineRuntimeBindingBundleFromRepository(
      stageId: 'stage_09_03',
      encounterId: 'ch9_encounter_03_mirage',
      cycleIndex: 1,
      repository: repository,
    );
    final mirage = mirageBundle.actorBindingsByEntryId['ch9_s03_mirage']!;
    expect(mirage.combatant.school, TechniqueSchool.yinRou);
    expect(mirage.attackSet, 'ch2_attack_set_lightfoot');
    expect(mirage.combatant.availableSkills.map((skill) => skill.id), [
      'skill_yinrou_jichu_basic',
    ]);
  });

  test('Chapter 9 routes construct through the real factory', () async {
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

  test('Chapter 9 objectives require every authored opponent', () {
    for (final stageId in ['stage_09_01', 'stage_09_02', 'stage_09_03']) {
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

  test('both authored Chapter 9 targets retain Boss identity', () {
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
    'all five Chapter 9 routes reach dynamic victory without stalls',
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
            rng: Random(2026090900 + index),
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
