import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';
import 'package:wuxia_idle/shared/battle_shared/enemy_combatant_snapshot_assembler.dart';

Future<String> _fileLoader(String path) async =>
    (await File(path).readAsString()).replaceAll('\r\n', '\n');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(GameRepository.resetForTest);

  test(
    'five Ch1 stages expose complete production encounter closures',
    () async {
      final repository = await GameRepository.loadAllDefs(
        loader: _fileLoader,
        assetExists: (path) async => File(path).existsSync(),
      );
      const expected = {
        'stage_01_01': ('ch1_encounter_01_roadbreak', 25, 10),
        'stage_01_02': ('ch1_encounter_02_stronghold', 25, 10),
        'stage_01_03': ('ch1_encounter_03_ambush', 40, 12),
        'stage_01_04': ('ch1_encounter_04_commander', 3, 3),
        'stage_01_05': ('ch1_encounter_05_commander', 2, 2),
      };

      for (final MapEntry(key: stageId, value: contract) in expected.entries) {
        final encounter = repository.combatEncounterForStage(stageId);
        final runtime = repository.combatRuntimeBindingForStage(stageId);
        expect(
          repository.combatAssignmentForStage(stageId)?.migrationState.name,
          'migrated',
          reason: stageId,
        );
        expect(encounter?.id, contract.$1, reason: stageId);
        expect(
          encounter?.spawnEntries,
          hasLength(contract.$2),
          reason: stageId,
        );
        expect(
          encounter?.spawnConfig.activeLimit,
          contract.$3,
          reason: stageId,
        );
        expect(runtime?.enemyBindings, hasLength(contract.$2), reason: stageId);

        final bundle = buildPhase0aMainlineRuntimeBindingBundleFromRepository(
          stageId: stageId,
          encounterId: contract.$1,
          cycleIndex: 1,
          repository: repository,
        );
        expect(bundle.actorBindingsByEntryId, hasLength(contract.$2));
        expect(
          bundle.actorBindingsByEntryId.values
              .map((binding) => binding.combatant.characterId)
              .toSet(),
          {for (var index = 1; index <= contract.$2; index++) -index},
          reason: '$stageId entries must keep distinct settlement identities',
        );

        final positions = <String>[];
        for (final entry in encounter!.spawnEntries) {
          final point = runtime!.bindingForEntry(entry.entryId)!.position;
          positions.add('${point.x}:${point.y}');
          if (positions.length >= contract.$3) {
            expect(
              positions.sublist(positions.length - contract.$3).toSet(),
              hasLength(contract.$3),
              reason: '$stageId active window must have unique positions',
            );
          }
        }
      }
    },
  );

  test('frozen Ch1 template tuning and coordinates stay exact', () async {
    final repository = await GameRepository.loadAllDefs(
      loader: _fileLoader,
      assetExists: (path) async => File(path).existsSync(),
    );
    const expectedTuning = {
      'stage_01_01': (25, 10, 2, 20, 10, 2, 1, 1, 0),
      'stage_01_02': (25, 10, 2, 24, 12, 1, 1, 1, 1),
      'stage_01_03': (40, 12, 3, 30, 15, 1, 1, 1, 1),
      'stage_01_04': (3, 3, 0, 20, 10, 1, 0, 1, 1),
      'stage_01_05': (2, 2, 0, 30, 15, 1, 0, 0, 1),
    };
    for (final MapEntry(key: stageId, value: tuning)
        in expectedTuning.entries) {
      final encounter = repository.combatEncounterForStage(stageId)!;
      expect(
        (
          encounter.spawnEntries.length,
          encounter.spawnConfig.activeLimit,
          encounter.spawnConfig.reinforcementThreshold,
          encounter.spawnConfig.entryWarningTicks,
          encounter.spawnConfig.attackGraceTicks,
          encounter.tokenBudgets.melee,
          encounter.tokenBudgets.ranged,
          encounter.tokenBudgets.charge,
          encounter.tokenBudgets.support,
        ),
        tuning,
        reason: stageId,
      );
    }

    const expectedPoints = {
      'stage_01_01': {
        'ch1_entrance_s01_road_west': (-520.0, 80.0),
        'ch1_entrance_s01_road_ridge': (0.0, -120.0),
        'ch1_entrance_s01_road_exit': (520.0, 80.0),
      },
      'stage_01_02': {
        'ch1_entrance_s02_gate': (-520.0, 80.0),
        'ch1_entrance_s02_roof': (0.0, -120.0),
        'ch1_entrance_s02_yard': (520.0, 80.0),
      },
      'stage_01_04': {
        'ch1_position_s04_guard_left': (-120.0, 120.0),
        'ch1_position_s04_guard_right': (120.0, 120.0),
        'ch1_position_s04_commander_center': (0.0, -40.0),
      },
      'stage_01_05': {
        'ch1_position_s05_guard': (-120.0, 120.0),
        'ch1_position_s05_commander_center': (0.0, -40.0),
      },
    };
    for (final MapEntry(key: stageId, value: points)
        in expectedPoints.entries) {
      final runtime = repository.combatRuntimeBindingForStage(stageId)!;
      for (final MapEntry(key: id, value: expected) in points.entries) {
        final point = runtime.entrances[id] ?? runtime.positions[id];
        expect((point?.x, point?.y), expected, reason: '$stageId/$id');
      }
    }
  });

  test(
    'only typed stage 4 and 5 commanders retain legacy Boss identity',
    () async {
      final repository = await GameRepository.loadAllDefs(
        loader: _fileLoader,
        assetExists: (path) async => File(path).existsSync(),
      );
      const cases = {
        'stage_01_04': (
          'ch1_encounter_04_commander',
          'ch1_s04_leader_01',
          ['ch1_s04_blade_01', 'ch1_s04_rope_01'],
        ),
        'stage_01_05': (
          'ch1_encounter_05_commander',
          'ch1_s05_leader_01',
          ['ch1_s05_blade_01'],
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
        final commanderActor = commander.createActor('runtime-commander');
        expect(commander.combatant.name, base.name, reason: stageId);
        expect(commander.combatant.iconPath, base.iconPath, reason: stageId);
        expect(commander.combatant.isBoss, isTrue, reason: stageId);
        expect(commanderActor.isBoss, isTrue, reason: stageId);
        expect(commanderActor.chargeCast?.skill.id, base.chargeSkillId);
        expect(commanderActor.bossPhases?.length, base.bossPhases?.length);
        expect(
          commander.combatant.availableSkills.map((skill) => skill.id),
          base.availableSkills.map((skill) => skill.id),
        );

        for (final guardId in identity.$3) {
          final guard = bundle.actorBindingsByEntryId[guardId]!;
          final guardActor = guard.createActor('runtime-$guardId');
          final runtimeEntry = repository
              .combatRuntimeBindingForStage(stageId)!
              .bindingForEntry(guardId)!;
          expect(guard.combatant.isBoss, isFalse, reason: guardId);
          expect(guardActor.isBoss, isFalse, reason: guardId);
          expect(
            guard.combatant.iconPath,
            runtimeEntry.visualVariant.assetPath,
          );
          expect(guard.combatant.chargeSkillId, isNull, reason: guardId);
          expect(guard.combatant.bossPhases, isNull, reason: guardId);
          expect(
            guard.combatant.bossPhaseUnlockSkills,
            isNull,
            reason: guardId,
          );
          expect(guard.combatant.guardianDefIds, isEmpty, reason: guardId);
          expect(guard.combatant.guardianWardMult, isNull, reason: guardId);
          expect(guard.combatant.vulnerabilityMult, isNull, reason: guardId);
          expect(guard.combatant.enemyDefId, isNull, reason: guardId);
          expect(guardActor.chargeCast, isNull, reason: guardId);
          expect(guardActor.phaseChargeCasts, isEmpty, reason: guardId);
        }
      }
    },
  );
}
