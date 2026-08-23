// Contract tests for the P2-G2-L01 combat catalog loader.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/combat_encounter_catalog_loader.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_manifest_def.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';

const fixtureRoot = 'test/fixtures/phase2/combat/catalog_loader';

Future<CombatCatalogYamlSource> fixtureSource(String relativePath) async {
  final content = await File('$fixtureRoot/$relativePath').readAsString();
  return (relativePath, content);
}

Future<List<CombatCatalogYamlSource>> archetypeFixtureSources() {
  return Future.wait([
    fixtureSource('archetypes/bandit.yaml'),
    fixtureSource('archetypes/wolf.yaml'),
    fixtureSource('archetypes/totem.yaml'),
    fixtureSource('archetypes/commander.yaml'),
  ]);
}

Future<List<CombatCatalogYamlSource>> encounterFixtureSources() {
  return Future.wait([
    fixtureSource('encounters/enc_defeat_targets.yaml'),
    fixtureSource('encounters/enc_destroy_anchors.yaml'),
    fixtureSource('encounters/enc_defend_entity.yaml'),
    fixtureSource('encounters/enc_survive_duration.yaml'),
    fixtureSource('encounters/enc_reach_checkpoint.yaml'),
    fixtureSource('encounters/enc_touch_markers.yaml'),
    fixtureSource('encounters/enc_pursue_target.yaml'),
    fixtureSource('encounters/enc_defeat_commander.yaml'),
  ]);
}

Future<CombatCatalogManifestDef> loadFixtureCatalog() async {
  return loadCombatCatalogManifest(
    archetypeSources: await archetypeFixtureSources(),
    encounterSources: await encounterFixtureSources(),
    manifestSource: await fixtureSource('manifest/stage_assignments.yaml'),
  );
}

Matcher failsWithFragment(String fragment) {
  return throwsA(
    isA<FormatException>().having(
      (e) => e.message,
      'message',
      contains(fragment),
    ),
  );
}

void main() {
  group('valid fixture catalog', () {
    test(
      'loads archetypes, encounters and assignments in source order',
      () async {
        final manifest = await loadFixtureCatalog();
        expect(manifest.archetypes.map((a) => a.id), [
          'arch_bandit',
          'arch_wolf',
          'arch_totem',
          'arch_commander',
        ]);
        expect(manifest.encounters.map((e) => e.id), [
          'cl_enc_defeat_targets',
          'cl_enc_destroy_anchors',
          'cl_enc_defend_entity',
          'cl_enc_survive_duration',
          'cl_enc_reach_checkpoint',
          'cl_enc_touch_markers',
          'cl_enc_pursue_target',
          'cl_enc_defeat_commander',
        ]);
        expect(manifest.stageAssignments, hasLength(9));
        expect(
          manifest.assignmentForStage('cl_stage_01')?.encounterId,
          'cl_enc_defeat_targets',
        );
        expect(
          manifest.encounterForStage('cl_stage_01')?.id,
          'cl_enc_defeat_targets',
        );
        final legacy = manifest.assignmentForStage('cl_stage_legacy_01');
        expect(legacy?.migrationState, CombatEncounterMigrationState.legacy);
        expect(legacy?.encounterId, isNull);
        expect(manifest.encounterForStage('cl_stage_legacy_01'), isNull);
        expect(manifest.encounterForStage('cl_unknown_stage'), isNull);
      },
    );

    test('covers all eight objective reference kinds', () async {
      final manifest = await loadFixtureCatalog();
      final objectiveByEncounterId = <String, CombatObjectivePrimitiveRef>{
        for (final encounter in manifest.encounters)
          encounter.id: encounter.objective,
      };
      expect(
        objectiveByEncounterId['cl_enc_defeat_targets'],
        isA<CombatDefeatTargetsRef>(),
      );
      expect(
        (objectiveByEncounterId['cl_enc_defeat_targets']
                as CombatDefeatTargetsRef)
            .targetIds,
        {'bandit_brute', 'bandit_scout'},
      );
      expect(
        objectiveByEncounterId['cl_enc_destroy_anchors'],
        isA<CombatDestroyAnchorsRef>(),
      );
      expect(
        objectiveByEncounterId['cl_enc_defend_entity'],
        isA<CombatDefendEntityRef>(),
      );
      expect(
        (objectiveByEncounterId['cl_enc_defend_entity']
                as CombatDefendEntityRef)
            .requiredTicks,
        600,
      );
      expect(
        objectiveByEncounterId['cl_enc_survive_duration'],
        isA<CombatSurviveDurationRef>(),
      );
      expect(
        objectiveByEncounterId['cl_enc_reach_checkpoint'],
        isA<CombatReachCheckpointRef>(),
      );
      expect(
        objectiveByEncounterId['cl_enc_touch_markers'],
        isA<CombatTouchMarkersRef>(),
      );
      expect(
        objectiveByEncounterId['cl_enc_pursue_target'],
        isA<CombatPursueTargetRef>(),
      );
      expect(
        objectiveByEncounterId['cl_enc_defeat_commander'],
        isA<CombatDefeatCommanderRef>(),
      );
    });

    test('parses spawn config and token budgets explicitly', () async {
      final manifest = await loadFixtureCatalog();
      final encounter = manifest.encounterById('cl_enc_defeat_targets')!;
      expect(encounter.spawnConfig.activeLimit, 4);
      expect(encounter.spawnConfig.reinforcementThreshold, 1);
      expect(encounter.spawnConfig.entryWarningTicks, 30);
      expect(encounter.spawnConfig.attackGraceTicks, 10);
      expect(encounter.tokenBudgets.melee, 3);
      expect(encounter.tokenBudgets.ranged, 2);
      expect(encounter.tokenBudgets.charge, 1);
      expect(encounter.tokenBudgets.support, 0);
      expect(encounter.spawnEntries, hasLength(3));
      expect(encounter.spawnEntries.first.archetypeId, 'arch_bandit');
      expect(encounter.spawnEntries.first.roleId, 'melee_brute');
      expect(
        manifest.archetypeById('arch_bandit')?.variantByRole('ranged_scout'),
        isNotNull,
      );
    });

    test('is deterministic across reloads', () async {
      final first = await loadFixtureCatalog();
      final second = await loadFixtureCatalog();
      expect(
        second.archetypes.map((a) => a.id),
        first.archetypes.map((a) => a.id),
      );
      expect(
        second.encounters.map((e) => e.id),
        first.encounters.map((e) => e.id),
      );
      expect(
        second.stageAssignments.map((a) => a.stageId),
        first.stageAssignments.map((a) => a.stageId),
      );
    });

    test('exposes unmodifiable collections', () async {
      final manifest = await loadFixtureCatalog();
      expect(
        () => manifest.archetypes.add(manifest.archetypes.first),
        throwsUnsupportedError,
      );
      expect(
        () => manifest.encounters.add(manifest.encounters.first),
        throwsUnsupportedError,
      );
      expect(
        () => manifest.stageAssignments.add(manifest.stageAssignments.first),
        throwsUnsupportedError,
      );
    });
  });

  group('fail closed', () {
    test('rejects a duplicate archetype id across sources', () async {
      final sources = await archetypeFixtureSources();
      sources.add((
        'archetypes/duplicate_bandit.yaml',
        'archetypes:\n'
            '  - id: arch_bandit\n'
            '    variants:\n'
            '      - role_id: chief\n'
            '        attack_token_kind: melee\n'
            '        hp_multiplier: 1.0\n'
            '        attack_multiplier: 1.0\n'
            '        defense_multiplier: 0.5\n'
            '        speed_multiplier: 1.0\n',
      ));
      await expectLater(
        () async => loadCombatCatalogManifest(
          archetypeSources: sources,
          encounterSources: await encounterFixtureSources(),
          manifestSource: await fixtureSource(
            'manifest/stage_assignments.yaml',
          ),
        ),
        failsWithFragment(
          'combat catalog source "archetypes/duplicate_bandit.yaml": '
          'archetypes[0].id: duplicate archetype id "arch_bandit"; '
          'first declared at source "archetypes/bandit.yaml": archetypes[0].id',
        ),
      );
    });

    test('rejects a duplicate encounter id across sources', () async {
      final sources = await encounterFixtureSources();
      sources.add((
        'encounters/duplicate_defeat_targets.yaml',
        'encounters:\n'
            '  - id: cl_enc_defeat_targets\n'
            '    spawn_config:\n'
            '      active_limit: 2\n'
            '      reinforcement_threshold: 0\n'
            '      entry_warning_ticks: 0\n'
            '      attack_grace_ticks: 0\n'
            '    token_budgets:\n'
            '      melee: 1\n'
            '      ranged: 0\n'
            '      charge: 0\n'
            '      support: 0\n'
            '    spawn_entries:\n'
            '      - entry_id: brute\n'
            '        archetype_id: arch_bandit\n'
            '        role_id: melee_brute\n'
            '    objective:\n'
            '      kind: survive_duration\n'
            '      required_ticks: 10\n',
      ));
      await expectLater(
        () async => loadCombatCatalogManifest(
          archetypeSources: await archetypeFixtureSources(),
          encounterSources: sources,
          manifestSource: await fixtureSource(
            'manifest/stage_assignments.yaml',
          ),
        ),
        failsWithFragment(
          'combat catalog source "encounters/duplicate_defeat_targets.yaml": '
          'encounters[0].id: duplicate encounter id "cl_enc_defeat_targets"; '
          'first declared at source "encounters/enc_defeat_targets.yaml": '
          'encounters[0].id',
        ),
      );
    });

    test('locates a duplicate role id at the second leaf field', () async {
      final archetypes = await archetypeFixtureSources();
      final bandit = archetypes.first;
      archetypes[0] = (
        bandit.$1,
        bandit.$2.replaceFirst('role_id: ranged_scout', 'role_id: melee_brute'),
      );
      await expectLater(
        () async => loadCombatCatalogManifest(
          archetypeSources: archetypes,
          encounterSources: await encounterFixtureSources(),
          manifestSource: await fixtureSource(
            'manifest/stage_assignments.yaml',
          ),
        ),
        failsWithFragment(
          'archetypes[0].variants[1].role_id: duplicate role id '
          '"melee_brute"; first declared at '
          'archetypes[0].variants[0].role_id',
        ),
      );
    });

    test(
      'locates a duplicate spawn entry id at the second leaf field',
      () async {
        final encounters = await encounterFixtureSources();
        final defeatTargets = encounters.first;
        encounters[0] = (
          defeatTargets.$1,
          defeatTargets.$2.replaceFirst(
            'entry_id: bandit_scout',
            'entry_id: bandit_brute',
          ),
        );
        await expectLater(
          () async => loadCombatCatalogManifest(
            archetypeSources: await archetypeFixtureSources(),
            encounterSources: encounters,
            manifestSource: await fixtureSource(
              'manifest/stage_assignments.yaml',
            ),
          ),
          failsWithFragment(
            'encounters[0].spawn_entries[1].entry_id: duplicate spawn entry id '
            '"bandit_brute"; first declared at '
            'encounters[0].spawn_entries[0].entry_id',
          ),
        );
      },
    );

    test('locates duplicate stage and encounter assignments', () async {
      final manifest = await fixtureSource('manifest/stage_assignments.yaml');
      final archetypes = await archetypeFixtureSources();
      final encounters = await encounterFixtureSources();

      await expectLater(
        () => loadCombatCatalogManifest(
          archetypeSources: archetypes,
          encounterSources: encounters,
          manifestSource: (
            manifest.$1,
            manifest.$2.replaceFirst(
              'stage_id: cl_stage_02',
              'stage_id: cl_stage_01',
            ),
          ),
        ),
        failsWithFragment(
          'stage_assignments[1].stage_id: duplicate stage id "cl_stage_01"; '
          'first declared at stage_assignments[0].stage_id',
        ),
      );

      await expectLater(
        () => loadCombatCatalogManifest(
          archetypeSources: archetypes,
          encounterSources: encounters,
          manifestSource: (
            manifest.$1,
            manifest.$2.replaceFirst(
              'encounter_id: cl_enc_destroy_anchors',
              'encounter_id: cl_enc_defeat_targets',
            ),
          ),
        ),
        failsWithFragment(
          'stage_assignments[1].encounter_id: duplicate assigned encounter id '
          '"cl_enc_defeat_targets"; first declared at '
          'stage_assignments[0].encounter_id',
        ),
      );
    });

    test('rejects a spawn entry referencing an unknown archetype', () async {
      await expectLater(
        () async => loadCombatCatalogManifest(
          archetypeSources: await archetypeFixtureSources(),
          encounterSources: [
            (
              'encounters/bad_archetype.yaml',
              'encounters:\n'
                  '  - id: enc_bad\n'
                  '    spawn_config:\n'
                  '      active_limit: 2\n'
                  '      reinforcement_threshold: 0\n'
                  '      entry_warning_ticks: 0\n'
                  '      attack_grace_ticks: 0\n'
                  '    token_budgets:\n'
                  '      melee: 1\n'
                  '      ranged: 0\n'
                  '      charge: 0\n'
                  '      support: 0\n'
                  '    spawn_entries:\n'
                  '      - entry_id: ghost\n'
                  '        archetype_id: arch_ghost\n'
                  '        role_id: wraith\n'
                  '    objective:\n'
                  '      kind: survive_duration\n'
                  '      required_ticks: 10\n',
            ),
          ],
          manifestSource: (
            'manifest/stages.yaml',
            'stage_assignments:\n'
                '  - stage_id: stage_01\n'
                '    migration_state: migrated\n'
                '    encounter_id: enc_bad\n',
          ),
        ),
        failsWithFragment(
          'combat catalog source "encounters/bad_archetype.yaml": '
          'encounters[0].spawn_entries[0].archetype_id: '
          'unknown archetype "arch_ghost"',
        ),
      );
    });

    test('rejects a spawn entry referencing an unknown role', () async {
      await expectLater(
        () async => loadCombatCatalogManifest(
          archetypeSources: await archetypeFixtureSources(),
          encounterSources: [
            (
              'encounters/bad_role.yaml',
              'encounters:\n'
                  '  - id: enc_bad\n'
                  '    spawn_config:\n'
                  '      active_limit: 2\n'
                  '      reinforcement_threshold: 0\n'
                  '      entry_warning_ticks: 0\n'
                  '      attack_grace_ticks: 0\n'
                  '    token_budgets:\n'
                  '      melee: 1\n'
                  '      ranged: 0\n'
                  '      charge: 0\n'
                  '      support: 0\n'
                  '    spawn_entries:\n'
                  '      - entry_id: brute\n'
                  '        archetype_id: arch_bandit\n'
                  '        role_id: chief\n'
                  '    objective:\n'
                  '      kind: survive_duration\n'
                  '      required_ticks: 10\n',
            ),
          ],
          manifestSource: (
            'manifest/stages.yaml',
            'stage_assignments:\n'
                '  - stage_id: stage_01\n'
                '    migration_state: migrated\n'
                '    encounter_id: enc_bad\n',
          ),
        ),
        failsWithFragment(
          'encounters[0].spawn_entries[0].role_id: '
          'unknown role "chief" for archetype "arch_bandit"',
        ),
      );
    });

    test('rejects a manifest referencing an unknown encounter', () async {
      await expectLater(
        () async => loadCombatCatalogManifest(
          archetypeSources: await archetypeFixtureSources(),
          encounterSources: [
            (
              'encounters/solo.yaml',
              'encounters:\n'
                  '  - id: enc_solo\n'
                  '    spawn_config:\n'
                  '      active_limit: 2\n'
                  '      reinforcement_threshold: 0\n'
                  '      entry_warning_ticks: 0\n'
                  '      attack_grace_ticks: 0\n'
                  '    token_budgets:\n'
                  '      melee: 1\n'
                  '      ranged: 0\n'
                  '      charge: 0\n'
                  '      support: 0\n'
                  '    spawn_entries:\n'
                  '      - entry_id: brute\n'
                  '        archetype_id: arch_bandit\n'
                  '        role_id: melee_brute\n'
                  '    objective:\n'
                  '      kind: survive_duration\n'
                  '      required_ticks: 10\n',
            ),
          ],
          manifestSource: (
            'manifest/stages.yaml',
            'stage_assignments:\n'
                '  - stage_id: stage_01\n'
                '    migration_state: migrated\n'
                '    encounter_id: enc_missing\n',
          ),
        ),
        failsWithFragment(
          'stage_assignments[0].encounter_id: unknown encounter "enc_missing"',
        ),
      );
    });

    test('rejects an encounter not assigned to any stage', () async {
      final encounters = await encounterFixtureSources();
      await expectLater(
        () async => loadCombatCatalogManifest(
          archetypeSources: await archetypeFixtureSources(),
          encounterSources: encounters,
          manifestSource: (
            'manifest/partial.yaml',
            'stage_assignments:\n'
                '  - stage_id: cl_stage_01\n'
                '    migration_state: migrated\n'
                '    encounter_id: cl_enc_defeat_targets\n',
          ),
        ),
        failsWithFragment(
          'combat catalog source "encounters/enc_destroy_anchors.yaml": '
          'encounters[0]: encounter "cl_enc_destroy_anchors" '
          'is not assigned to any stage',
        ),
      );
    });

    test(
      'propagates structural violations with source name and path',
      () async {
        final sources = await archetypeFixtureSources();
        sources.add((
          'archetypes/broken.yaml',
          'archetypes:\n'
              '  - id: arch_broken\n'
              '    extra: 1\n'
              '    variants: []\n',
        ));
        await expectLater(
          () async => loadCombatCatalogManifest(
            archetypeSources: sources,
            encounterSources: await encounterFixtureSources(),
            manifestSource: await fixtureSource(
              'manifest/stage_assignments.yaml',
            ),
          ),
          failsWithFragment(
            'combat catalog source "archetypes/broken.yaml": '
            'archetypes[0]: unknown key',
          ),
        );
      },
    );

    test(
      'surfaces typed semantic violations with source and field path',
      () async {
        await expectLater(
          () async => loadCombatCatalogManifest(
            archetypeSources: await archetypeFixtureSources(),
            encounterSources: [
              (
                'encounters/negative_budget.yaml',
                'encounters:\n'
                    '  - id: enc_bad\n'
                    '    spawn_config:\n'
                    '      active_limit: 2\n'
                    '      reinforcement_threshold: 0\n'
                    '      entry_warning_ticks: 0\n'
                    '      attack_grace_ticks: 0\n'
                    '    token_budgets:\n'
                    '      melee: -1\n'
                    '      ranged: 0\n'
                    '      charge: 0\n'
                    '      support: 0\n'
                    '    spawn_entries:\n'
                    '      - entry_id: brute\n'
                    '        archetype_id: arch_bandit\n'
                    '        role_id: melee_brute\n'
                    '    objective:\n'
                    '      kind: survive_duration\n'
                    '      required_ticks: 10\n',
              ),
            ],
            manifestSource: (
              'manifest/stages.yaml',
              'stage_assignments:\n'
                  '  - stage_id: stage_01\n'
                  '    migration_state: migrated\n'
                  '    encounter_id: enc_bad\n',
            ),
          ),
          failsWithFragment(
            'combat catalog source "encounters/negative_budget.yaml": '
            'encounters[0].token_budgets.melee: must not be negative',
          ),
        );
      },
    );

    test('rejects a legacy assignment carrying an encounter id', () async {
      await expectLater(
        () async => loadCombatCatalogManifest(
          archetypeSources: await archetypeFixtureSources(),
          encounterSources: await encounterFixtureSources(),
          manifestSource: (
            'manifest/bad_legacy.yaml',
            'stage_assignments:\n'
                '  - stage_id: cl_stage_01\n'
                '    migration_state: migrated\n'
                '    encounter_id: cl_enc_defeat_targets\n'
                '  - stage_id: cl_stage_legacy_01\n'
                '    migration_state: legacy\n'
                '    encounter_id: cl_enc_defeat_commander\n',
          ),
        ),
        failsWithFragment('stage_assignments[1]: unknown key'),
      );
    });
  });
}
