import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/validation/combat_objective_primitive_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
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
}
