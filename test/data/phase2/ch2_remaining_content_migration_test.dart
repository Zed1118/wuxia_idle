import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
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
  'stage_02_03': ('ch2_encounter_03_springwater_hall', 25, 10),
  'stage_02_04': ('ch2_encounter_04_drill_ground', 3, 3),
  'stage_02_05': ('ch2_encounter_05_rainy_alley', 2, 2),
};

const _chapter2StageIds = [
  'stage_02_01',
  'stage_02_02',
  'stage_02_03',
  'stage_02_04',
  'stage_02_05',
];

const _expectedEffectiveRoleProfiles = <String, Set<String>>{
  'stage_02_01': {
    'poison_blood_blade:2750:100:0.05:150:false',
    'poison_dart:2000:100:0.04:150:false',
    'poison_master:3250:100:0.06:135:false',
    'poison_shadow_assassin:2750:100:0.05:165:false',
  },
  'stage_02_02': {
    'sect_hidden_weapon:3280:290:0.04:145:false',
    'sect_instructor:5330:290:0.06:131:false',
    'sect_lightfoot:4510:290:0.05:160:false',
    'sect_outer:4100:290:0.05:145:false',
  },
  'stage_02_03': {
    'sect_hidden_weapon:1760:170:0.04:165:false',
    'sect_instructor:2860:170:0.06:149:false',
    'sect_lightfoot:2420:170:0.05:182:false',
    'sect_outer:2200:170:0.05:165:false',
  },
  'stage_02_04': {
    'sect_instructor:2990:60:0.06:135:true',
    'sect_lightfoot:2530:60:0.05:165:false',
    'sect_outer:2300:60:0.05:150:false',
  },
  'stage_02_05': {
    'sect_instructor:10530:770:0.06:158:true',
    'sect_outer:8100:770:0.05:175:false',
  },
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

  test('Chapter 2 exposes five of five migrated production routes', () {
    final chapterStageIds = repository.stageDefs.values
        .where((stage) => stage.chapterIndex == 2)
        .map((stage) => stage.id)
        .toSet();
    expect(chapterStageIds, {
      'stage_02_01',
      'stage_02_02',
      'stage_02_03',
      'stage_02_04',
      'stage_02_05',
    });
    for (final stageId in chapterStageIds) {
      expect(
        repository.combatAssignmentForStage(stageId)?.migrationState,
        CombatEncounterMigrationState.migrated,
        reason: stageId,
      );
      expect(repository.combatEncounterForStage(stageId), isNotNull);
      expect(repository.combatRuntimeBindingForStage(stageId), isNotNull);
    }
  });

  test('remaining Chapter 2 routes close catalog and runtime identities', () {
    for (final MapEntry(key: stageId, value: contract) in _expected.entries) {
      final stage = repository.getStage(stageId);
      final assignment = repository.combatAssignmentForStage(stageId);
      final encounter = repository.combatEncounterForStage(stageId);
      final runtime = repository.combatRuntimeBindingForStage(stageId);
      expect(assignment?.encounterId, contract.$1, reason: stageId);
      expect(encounter?.spawnEntries, hasLength(contract.$2), reason: stageId);
      expect(encounter?.spawnConfig.activeLimit, contract.$3, reason: stageId);
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
        if (positions.length >= contract.$3) {
          expect(
            positions.sublist(positions.length - contract.$3).toSet(),
            hasLength(contract.$3),
            reason: '$stageId active window must keep unique positions',
          );
        }
      }
    }
  });

  test(
    'remaining Chapter 2 routes construct through the real factory',
    () async {
      final playerMapping = Phase0aStageContentMapper.mapPlayerOnly(
        contentId: 'stage_02_03',
        playerSnapshot: testCombatantSnapshot(
          includeProductionBasicAttack: true,
        ),
        numbers: repository.numbers,
      );
      final source = Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
        loader:
            ({required stageId, required encounterId, required cycleIndex}) =>
                buildPhase0aMainlineRuntimeBindingBundleFromRepository(
                  stageId: stageId,
                  encounterId: encounterId,
                  cycleIndex: cycleIndex,
                  repository: repository,
                ),
      );
      for (final MapEntry(key: stageId, value: contract) in _expected.entries) {
        final host = await createFreshPhase0aMainlineEncounter(
          Phase0aMainlineEncounterHostBuildRequest(
            stage: repository.getStage(stageId),
            playerMapping: playerMapping,
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
    },
  );

  test('remaining Chapter 2 objectives complete only on authored defeats', () {
    final ordinary = repository.combatEncounterForStage('stage_02_03')!;
    final ordinaryController = mapCombatObjectiveComposition(
      ordinary.objectives,
      tickDuration: const Duration(milliseconds: 100),
    );
    var ordinaryProgress = ordinaryController.initialProgress;
    for (var index = 0; index < ordinary.spawnEntries.length; index++) {
      ordinaryProgress = ordinaryController.advance(
        ordinaryProgress,
        TargetDefeated(ordinary.spawnEntries[index].entryId),
      );
      expect(
        ordinaryProgress.completed,
        index == ordinary.spawnEntries.length - 1,
      );
    }

    final drill = repository.combatEncounterForStage('stage_02_04')!;
    final drillController = mapCombatObjectiveComposition(
      drill.objectives,
      tickDuration: const Duration(milliseconds: 100),
    );
    var drillProgress = drillController.initialProgress;
    drillProgress = drillController.advance(
      drillProgress,
      CommanderDefeated('ch2_s04_instructor_01'),
    );
    expect(drillProgress.completed, isFalse);
    drillProgress = drillController.advance(
      drillProgress,
      TargetDefeated('ch2_s04_outer_01'),
    );
    expect(drillProgress.completed, isFalse);
    drillProgress = drillController.advance(
      drillProgress,
      TargetDefeated('ch2_s04_lightfoot_01'),
    );
    expect(drillProgress.completed, isTrue);

    final alley = repository.combatEncounterForStage('stage_02_05')!;
    final alleyController = mapCombatObjectiveComposition(
      alley.objectives,
      tickDuration: const Duration(milliseconds: 100),
    );
    final alleyProgress = alleyController.advance(
      alleyController.initialProgress,
      CommanderDefeated('ch2_s05_instructor_01'),
    );
    expect(alleyProgress.completed, isTrue);
  });

  test('only the two Chapter 2 commanders retain authored Boss identity', () {
    const cases = {
      'stage_02_04': (
        'ch2_encounter_04_drill_ground',
        'ch2_s04_instructor_01',
        ['ch2_s04_outer_01', 'ch2_s04_lightfoot_01'],
      ),
      'stage_02_05': (
        'ch2_encounter_05_rainy_alley',
        'ch2_s05_instructor_01',
        ['ch2_s05_outer_01'],
      ),
    };
    for (final MapEntry(key: stageId, value: identity) in cases.entries) {
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

  test('Chapter 2 effective role profiles stay explicit after multipliers', () {
    for (final stageId in _chapter2StageIds) {
      final encounter = repository.combatEncounterForStage(stageId)!;
      final bundle = buildPhase0aMainlineRuntimeBindingBundleFromRepository(
        stageId: stageId,
        encounterId: encounter.id,
        cycleIndex: 1,
        repository: repository,
      );
      final signatures = <String>{};
      for (final entry in encounter.spawnEntries) {
        final combatant =
            bundle.actorBindingsByEntryId[entry.entryId]!.combatant;
        signatures.add(
          '${entry.roleId}:${combatant.maxHp}:${combatant.totalEquipmentAttack}:'
          '${combatant.defenseRate.toStringAsFixed(2)}:${combatant.speed}:'
          '${combatant.isBoss}',
        );
      }
      expect(
        signatures,
        _expectedEffectiveRoleProfiles[stageId],
        reason: '$stageId effective profile audit receipt',
      );
    }
  });

  test(
    'all five Chapter 2 routes reach real dynamic victory without stalls',
    () async {
      final source = Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
        loader:
            ({required stageId, required encounterId, required cycleIndex}) =>
                buildPhase0aMainlineRuntimeBindingBundleFromRepository(
                  stageId: stageId,
                  encounterId: encounterId,
                  cycleIndex: cycleIndex,
                  repository: repository,
                ),
      );
      final maxTicks = repository.numbers.phase0aArena.maxSimulationTicks;
      final deltaSeconds = repository.numbers.phase0aArena.fixedDeltaSeconds;
      for (var index = 0; index < _chapter2StageIds.length; index++) {
        final stageId = _chapter2StageIds[index];
        final playerMapping = Phase0aStageContentMapper.mapPlayerOnly(
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
        final host = (await createFreshPhase0aMainlineEncounter(
          Phase0aMainlineEncounterHostBuildRequest(
            stage: repository.getStage(stageId),
            playerMapping: playerMapping,
            numbers: repository.numbers,
            cycleIndex: 1,
            rng: Random(2026090200 + index),
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
        expect(
          result.ticks,
          inInclusiveRange(1, maxTicks - 1),
          reason: stageId,
        );
        expect(result.finalState.player.isAlive, isTrue, reason: stageId);
        expect(
          result.events.whereType<Phase0aEnemyDefeated>(),
          isNotEmpty,
          reason: '$stageId must exercise real combat before victory',
        );
        if (stageId == 'stage_02_01') {
          expect(result.finalState.defendedEntity, isNotNull);
          expect(result.finalState.defendedEntity!.isAlive, isTrue);
          expect(
            result.events.whereType<Phase0aDefendedEntityDestroyed>(),
            isEmpty,
          );
        }
        if (stageId == 'stage_02_02') {
          expect(result.ticks, greaterThanOrEqualTo(900));
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
