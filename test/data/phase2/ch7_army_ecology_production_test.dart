import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/validation/combat_objective_primitive_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_enemy_behavior_profile.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';

import '../../support/combatant_snapshot_fixture.dart';

const _stageId = 'stage_07_01';
const _encounterId = 'ch7_encounter_01_northern_outpost';
const _archetypeId = 'ch7_army';
const _roleCounts = {
  'army_shield': 12,
  'army_archer': 6,
  'army_spear_charger': 5,
  'army_standard_officer': 2,
};
const _roleNames = {
  'army_shield': '盾兵',
  'army_archer': '弓手',
  'army_spear_charger': '枪骑冲阵兵',
  'army_standard_officer': '掌旗军官',
};
const _tokensByRole = {
  'army_shield': AttackTokenKind.melee,
  'army_archer': AttackTokenKind.ranged,
  'army_spear_charger': AttackTokenKind.charge,
  'army_standard_officer': AttackTokenKind.support,
};
const _movementByRole = {
  'army_shield': Phase0aEnemyMovementPolicy.guardedPosition,
  'army_archer': Phase0aEnemyMovementPolicy.holdDistance,
  'army_spear_charger': Phase0aEnemyMovementPolicy.lateralFlank,
  'army_standard_officer': Phase0aEnemyMovementPolicy.guardedPosition,
};
const _attackByRole = {
  'army_shield': Phase0aEnemyAttackPolicy.closeRange,
  'army_archer': Phase0aEnemyAttackPolicy.rangedPressure,
  'army_spear_charger': Phase0aEnemyAttackPolicy.chargeAndReposition,
  'army_standard_officer': Phase0aEnemyAttackPolicy.supportPulse,
};

Future<String> _fileLoader(String path) async =>
    (await File(path).readAsString()).replaceAll('\r\n', '\n');

Phase0aMainlineEncounterRuntimeBindingSourceAdapter _runtimeSource(
  GameRepository repository,
) => Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
  loader:
      ({required stageId, required encounterId, required cycleIndex}) async =>
          buildPhase0aMainlineRuntimeBindingBundleFromRepository(
            stageId: stageId,
            encounterId: encounterId,
            cycleIndex: cycleIndex,
            repository: repository,
          ),
);

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

  test('stage_07_01 routes to the exact four-role army encounter', () {
    final manifest = repository.combatCatalog!;
    final assignment = manifest.assignmentForStage(_stageId);
    final encounter = manifest.encounterForStage(_stageId)!;
    final archetype = manifest.archetypeById(_archetypeId)!;

    expect(assignment?.migrationState, CombatEncounterMigrationState.migrated);
    expect(assignment?.encounterId, _encounterId);
    expect(encounter.id, _encounterId);
    expect(encounter.spawnEntries, hasLength(25));
    expect(encounter.spawnConfig.activeLimit, 10);
    expect(encounter.tokenBudgets.melee, 2);
    expect(encounter.tokenBudgets.ranged, 1);
    expect(encounter.tokenBudgets.charge, 1);
    expect(encounter.tokenBudgets.support, 1);

    final actualRoleCounts = <String, int>{};
    for (final entry in encounter.spawnEntries) {
      actualRoleCounts.update(
        entry.roleId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      expect(entry.archetypeId, _archetypeId);
    }
    expect(actualRoleCounts, _roleCounts);
    expect({
      for (final variant in archetype.variants)
        variant.roleId: variant.displayName,
    }, _roleNames);
    for (final variant in archetype.variants) {
      expect(variant.visualVariantIds, hasLength(2), reason: variant.roleId);
      expect(variant.attackTagIds, isNotEmpty, reason: variant.roleId);
      expect(variant.attackSetId, startsWith('ch7_attack_set_'));
      expect(variant.postureProfileId, startsWith('ch7_posture_'));
      expect(variant.dropGroupId, 'ch7_drop_group_army_encounter');
      expect(variant.sfxGroupId, startsWith('ch7_sfx_'));
    }
  });

  test(
    'typed runtime bundle and production host close all 25 army actors',
    () async {
      final encounter = repository.combatEncounterForStage(_stageId)!;
      final bundle = buildPhase0aMainlineRuntimeBindingBundleFromRepository(
        stageId: _stageId,
        encounterId: _encounterId,
        cycleIndex: 1,
        repository: repository,
      );
      expect(bundle.actorBindingsByEntryId, hasLength(25));
      expect(bundle.actorBindingsByEntryId.keys.toSet(), {
        for (final entry in encounter.spawnEntries) entry.entryId,
      });

      final namesByRole = <String, Set<String>>{};
      final visualsByRole = <String, Set<String>>{};
      final tokensByRole = <String, Set<AttackTokenKind>>{};
      for (final entry in encounter.spawnEntries) {
        final binding = bundle.actorBindingsByEntryId[entry.entryId]!;
        namesByRole
            .putIfAbsent(entry.roleId, () => <String>{})
            .add(binding.combatant.name);
        visualsByRole
            .putIfAbsent(entry.roleId, () => <String>{})
            .add(binding.visualAssetPath);
        tokensByRole
            .putIfAbsent(entry.roleId, () => <AttackTokenKind>{})
            .add(binding.token.kind);
        expect(File(binding.visualAssetPath).existsSync(), isTrue);
        expect(binding.behaviorProfile, isNotNull);
        expect(
          binding.behaviorProfile!.movementPolicy,
          _movementByRole[entry.roleId],
          reason: entry.roleId,
        );
        expect(
          binding.behaviorProfile!.attackPolicy,
          _attackByRole[entry.roleId],
          reason: entry.roleId,
        );
        expect(binding.token.kind, _tokensByRole[entry.roleId]);
        expect(binding.combatant.skillLoadout.basicAttack, isNotNull);
        expect(
          binding.enemySkillBindings,
          entry.roleId == 'army_standard_officer' ? isNotEmpty : isEmpty,
          reason: entry.roleId,
        );
      }
      expect(
        namesByRole,
        _roleNames.map((role, name) => MapEntry(role, {name})),
      );
      expect(visualsByRole, {
        for (final role in _roleCounts.keys) role: hasLength(2),
      });
      expect(tokensByRole, {
        for (final entry in _tokensByRole.entries) entry.key: {entry.value},
      });

      final playerMapping = Phase0aStageContentMapper.mapPlayerOnly(
        contentId: _stageId,
        playerSnapshot: testCombatantSnapshot(
          maxHp: 15000,
          currentHp: 15000,
          maxQi: 100,
          currentQi: 100,
          includeProductionBasicAttack: true,
        ),
        numbers: repository.numbers,
      );
      final host = await createFreshPhase0aMainlineEncounter(
        Phase0aMainlineEncounterHostBuildRequest(
          stage: repository.getStage(_stageId),
          playerMapping: playerMapping,
          numbers: repository.numbers,
          cycleIndex: 1,
          rng: Random(20260831),
          runtimeBindingSource: _runtimeSource(repository),
          catalogOverride: repository.combatCatalog,
        ),
      );
      expect(host, isNotNull);
      expect(host!.mapping!.combatants, hasLength(26));
      expect(host.mapping!.director.config.activeLimit, 10);
      expect(
        host.mapping!.enemyAiAdapter.behaviorProfilesByActor,
        hasLength(25),
      );
      expect(host.tokenBindingsByActorId, hasLength(25));

      final positions = [
        for (final entry in encounter.spawnEntries)
          bundle.actorBindingsByEntryId[entry.entryId]!
              .createActor(entry.entryId)
              .position,
      ];
      for (var start = 0; start <= positions.length - 10; start++) {
        expect(
          positions.sublist(start, start + 10).toSet(),
          hasLength(10),
          reason: 'active position window start=$start',
        );
      }
    },
  );

  test('all 25 army defeat projections complete the objective', () async {
    final encounter = repository.combatEncounterForStage(_stageId)!;
    final bundle = buildPhase0aMainlineRuntimeBindingBundleFromRepository(
      stageId: _stageId,
      encounterId: _encounterId,
      cycleIndex: 1,
      repository: repository,
    );
    final playerMapping = Phase0aStageContentMapper.mapPlayerOnly(
      contentId: _stageId,
      playerSnapshot: testCombatantSnapshot(includeProductionBasicAttack: true),
      numbers: repository.numbers,
    );
    final host = (await createFreshPhase0aMainlineEncounter(
      Phase0aMainlineEncounterHostBuildRequest(
        stage: repository.getStage(_stageId),
        playerMapping: playerMapping,
        numbers: repository.numbers,
        cycleIndex: 1,
        rng: Random(7),
        runtimeBindingSource: _runtimeSource(repository),
        catalogOverride: repository.combatCatalog,
      ),
    ))!;
    final mapping = host.mapping!;
    final objectiveEvents =
        buildPhase0aMainlineObjectiveEventSource(
          encounter: encounter,
          roster: mapping.roster,
        ).eventsFor(
          Phase0aEncounterObjectiveFrame(
            beforeArena: mapping.initialState,
            afterArena: mapping.initialState,
            beforeSpawn: mapping.director.state,
            afterSpawn: mapping.director.state,
            directorEvents: const [],
            spawnEvents: const [],
            combatEvents: [
              for (
                var index = 0;
                index < encounter.spawnEntries.length;
                index++
              )
                Phase0aEnemyDefeated(
                  seq: index + 1,
                  tick: 1,
                  target: mapping.roster
                      .bindingByEntryId(encounter.spawnEntries[index].entryId)!
                      .actorId,
                  defeatKind: bundle
                      .actorBindingsByEntryId[encounter
                          .spawnEntries[index]
                          .entryId]!
                      .createActor('probe')
                      .defeatKind,
                ),
            ],
            deltaSeconds: 0.1,
            playerMovementDelta: playerMapping.initialPlayer.position * 0,
          ),
        );
    expect(objectiveEvents, hasLength(25));

    final controller = mapCombatObjectiveComposition(
      encounter.objectives,
      tickDuration: const Duration(milliseconds: 100),
    );
    var progress = controller.initialProgress;
    for (final event in objectiveEvents) {
      progress = controller.advance(progress, event);
    }
    expect(progress.completed, isTrue);
    expect(progress.clauses.single.completed, isTrue);
  });
}
