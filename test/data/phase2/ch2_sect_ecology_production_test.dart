import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/validation/combat_objective_primitive_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';

import '../../support/combatant_snapshot_fixture.dart';

const _stageId = 'stage_02_02';
const _encounterId = 'ch2_encounter_02_teahouse';
const _roleCounts = {
  'sect_outer': 14,
  'sect_hidden_weapon': 6,
  'sect_lightfoot': 4,
  'sect_instructor': 1,
};
const _roleNames = {
  'sect_outer': '外门弟子',
  'sect_hidden_weapon': '暗器弟子',
  'sect_lightfoot': '轻功弟子',
  'sect_instructor': '教习',
};

Future<String> _fileLoader(String path) async =>
    (await File(path).readAsString()).replaceAll('\r\n', '\n');

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

  test('stage_02_02 routes to the exact four-role sect encounter', () {
    final manifest = repository.combatCatalog!;
    final assignment = manifest.assignmentForStage(_stageId);
    final encounter = manifest.encounterForStage(_stageId)!;
    final archetype = manifest.archetypeById('ch2_sects')!;

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
      expect(entry.archetypeId, 'ch2_sects');
    }
    expect(actualRoleCounts, _roleCounts);
    expect({
      for (final variant in archetype.variants)
        variant.roleId: variant.displayName,
    }, _roleNames);
    for (final variant in archetype.variants) {
      expect(variant.visualVariantIds, hasLength(2), reason: variant.roleId);
      expect(variant.attackTagIds, isNotEmpty, reason: variant.roleId);
      expect(variant.attackSetId, startsWith('ch2_attack_set_'));
      expect(variant.postureProfileId, startsWith('ch2_posture_'));
      expect(variant.dropGroupId, 'ch2_drop_group_sect_encounter');
      expect(variant.sfxGroupId, startsWith('ch2_sfx_'));
    }
  });

  test(
    'typed runtime bundle and production host close all 25 actors',
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
        expect(binding.combatant.skillLoadout.basicAttack, isNotNull);
        expect(
          binding.enemySkillBindings,
          entry.roleId == 'sect_instructor' ? isNotEmpty : isEmpty,
          reason: entry.roleId,
        );
      }
      expect(
        namesByRole,
        _roleNames.map((role, name) => MapEntry(role, {name})),
      );
      expect(visualsByRole, {
        'sect_outer': hasLength(2),
        'sect_hidden_weapon': hasLength(2),
        'sect_lightfoot': hasLength(2),
        'sect_instructor': hasLength(1),
      });
      expect(tokensByRole, {
        'sect_outer': {AttackTokenKind.melee},
        'sect_hidden_weapon': {AttackTokenKind.ranged},
        'sect_lightfoot': {AttackTokenKind.charge},
        'sect_instructor': {AttackTokenKind.support},
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
      final source = Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
        loader:
            ({
              required stageId,
              required encounterId,
              required cycleIndex,
            }) async => buildPhase0aMainlineRuntimeBindingBundleFromRepository(
              stageId: stageId,
              encounterId: encounterId,
              cycleIndex: cycleIndex,
              repository: repository,
            ),
      );
      final host = await createFreshPhase0aMainlineEncounter(
        Phase0aMainlineEncounterHostBuildRequest(
          stage: repository.getStage(_stageId),
          playerMapping: playerMapping,
          numbers: repository.numbers,
          cycleIndex: 1,
          rng: Random(20260830),
          runtimeBindingSource: source,
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

  test(
    '900 production frame projections complete the survive objective',
    () async {
      final encounter = repository.combatEncounterForStage(_stageId)!;
      final playerMapping = Phase0aStageContentMapper.mapPlayerOnly(
        contentId: _stageId,
        playerSnapshot: testCombatantSnapshot(
          includeProductionBasicAttack: true,
        ),
        numbers: repository.numbers,
      );
      final source = Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
        loader:
            ({
              required stageId,
              required encounterId,
              required cycleIndex,
            }) async => buildPhase0aMainlineRuntimeBindingBundleFromRepository(
              stageId: stageId,
              encounterId: encounterId,
              cycleIndex: cycleIndex,
              repository: repository,
            ),
      );
      final host = (await createFreshPhase0aMainlineEncounter(
        Phase0aMainlineEncounterHostBuildRequest(
          stage: repository.getStage(_stageId),
          playerMapping: playerMapping,
          numbers: repository.numbers,
          cycleIndex: 1,
          rng: Random(7),
          runtimeBindingSource: source,
          catalogOverride: repository.combatCatalog,
        ),
      ))!;
      final mapping = host.mapping!;
      final objectiveSource = buildPhase0aMainlineObjectiveEventSource(
        encounter: encounter,
        roster: mapping.roster,
      );
      final controller = mapCombatObjectiveComposition(
        encounter.objectives,
        tickDuration: const Duration(milliseconds: 100),
      );
      var progress = controller.initialProgress;
      Phase0aArenaState atTick(int tick) => Phase0aArenaState(
        tick: tick,
        nextSeq: mapping.initialState.nextSeq,
        player: mapping.initialState.player,
        enemies: mapping.initialState.enemies,
        skillSlots: mapping.initialState.skillSlots,
      );
      for (var tick = 1; tick <= 900; tick++) {
        final objectiveEvents = objectiveSource.eventsFor(
          Phase0aEncounterObjectiveFrame(
            beforeArena: atTick(tick - 1),
            afterArena: atTick(tick),
            beforeSpawn: mapping.director.state,
            afterSpawn: mapping.director.state,
            directorEvents: const [],
            spawnEvents: const [],
            combatEvents: const [],
            deltaSeconds: 0.1,
            playerMovementDelta: playerMapping.initialPlayer.position * 0,
          ),
        );
        expect(objectiveEvents, hasLength(1));
        expect(objectiveEvents.single, isA<TimeElapsed>());
        progress = controller.advance(progress, objectiveEvents.single);
      }
      expect(progress.completed, isTrue);
      expect(progress.clauses.single.completed, isTrue);
    },
  );
}
