// Contract tests for the P2-G2-L01 combat catalog structural validator.

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/validation/combat_encounter_catalog_validator.dart';

Matcher failsWithSource(String sourceName, String pathFragment) {
  return throwsA(
    isA<FormatException>().having(
      (e) => e.message,
      'message',
      allOf(
        contains('combat catalog source "$sourceName"'),
        contains(pathFragment),
      ),
    ),
  );
}

const validArchetypeYaml = '''
archetypes:
  - id: arch_bandit
    variants:
      - role_id: melee_brute
        attack_token_kind: melee
        hp_multiplier: 1.0
        attack_multiplier: 1.0
        defense_multiplier: 0.5
        speed_multiplier: 1.0
      - role_id: ranged_scout
        attack_token_kind: ranged
        hp_multiplier: 0.8
        attack_multiplier: 1.2
        defense_multiplier: 0.3
        speed_multiplier: 1.1
''';

const validEncounterYaml = '''
encounters:
  - id: enc_ambush
    spawn_config:
      active_limit: 4
      reinforcement_threshold: 1
      entry_warning_ticks: 30
      attack_grace_ticks: 10
    token_budgets:
      melee: 3
      ranged: 2
      charge: 1
      support: 1
    spawn_entries:
      - entry_id: brute_a
        archetype_id: arch_bandit
        role_id: melee_brute
    objective:
      kind: defeat_targets
      target_ids: [brute_a]
''';

const validAssignmentYaml = '''
stage_assignments:
  - stage_id: stage_01
    migration_state: migrated
    encounter_id: enc_ambush
  - stage_id: stage_02
    migration_state: legacy
''';

void main() {
  group('validateCombatArchetypeSource', () {
    test('parses a valid source into entries', () {
      final source = validateCombatArchetypeSource(
        'arch.yaml',
        validArchetypeYaml,
      );
      expect(source.sourceName, 'arch.yaml');
      expect(source.archetypes, hasLength(1));
      final archetype = source.archetypes.single;
      expect(archetype.id, 'arch_bandit');
      expect(archetype.variants, hasLength(2));
      final brute = archetype.variants[0];
      expect(brute.roleId, 'melee_brute');
      expect(brute.attackTokenKind, 'melee');
      expect(brute.hpMultiplier, 1.0);
      expect(brute.attackMultiplier, 1.0);
      expect(brute.defenseMultiplier, 0.5);
      expect(brute.speedMultiplier, 1.0);
      expect(archetype.variants[1].roleId, 'ranged_scout');
      expect(archetype.variants[1].attackTokenKind, 'ranged');
    });

    test('rejects a non-map top level', () {
      expect(
        () => validateCombatArchetypeSource('arch.yaml', '- 1'),
        failsWithSource('arch.yaml', 'top level must be a map'),
      );
    });

    test('rejects malformed yaml with the source name', () {
      expect(
        () => validateCombatArchetypeSource('arch.yaml', 'archetypes: ['),
        failsWithSource('arch.yaml', 'document root'),
      );
    });

    test('rejects an unknown top-level key', () {
      expect(
        () => validateCombatArchetypeSource(
          'arch.yaml',
          'archetypes: []\nbonus: 1\n',
        ),
        failsWithSource('arch.yaml', 'unknown key'),
      );
    });

    test('rejects a missing archetypes key', () {
      expect(
        () => validateCombatArchetypeSource('arch.yaml', '{}\n'),
        failsWithSource('arch.yaml', 'missing required key "archetypes"'),
      );
    });

    test('rejects an empty archetypes list', () {
      expect(
        () => validateCombatArchetypeSource('arch.yaml', 'archetypes: []\n'),
        failsWithSource('arch.yaml', 'archetypes: must not be empty'),
      );
    });

    test('rejects an archetype with an unknown key', () {
      expect(
        () => validateCombatArchetypeSource(
          'arch.yaml',
          'archetypes:\n'
              '  - id: arch_bandit\n'
              '    hit_points: 10\n'
              '    variants:\n'
              '      - role_id: melee_brute\n'
              '        attack_token_kind: melee\n'
              '        hp_multiplier: 1.0\n'
              '        attack_multiplier: 1.0\n'
              '        defense_multiplier: 0.5\n'
              '        speed_multiplier: 1.0\n',
        ),
        failsWithSource('arch.yaml', 'archetypes[0]: unknown key'),
      );
    });

    test('rejects a non-string archetype id', () {
      expect(
        () => validateCombatArchetypeSource(
          'arch.yaml',
          'archetypes:\n'
              '  - id: 7\n'
              '    variants:\n'
              '      - role_id: melee_brute\n'
              '        attack_token_kind: melee\n'
              '        hp_multiplier: 1.0\n'
              '        attack_multiplier: 1.0\n'
              '        defense_multiplier: 0.5\n'
              '        speed_multiplier: 1.0\n',
        ),
        failsWithSource('arch.yaml', 'archetypes[0].id'),
      );
    });

    test('rejects a whitespace archetype id at the leaf path', () {
      expect(
        () => validateCombatArchetypeSource(
          'arch.yaml',
          validArchetypeYaml.replaceFirst('id: arch_bandit', 'id: "bad id"'),
        ),
        failsWithSource(
          'arch.yaml',
          'archetypes[0].id: must not contain whitespace',
        ),
      );
    });

    test('rejects a missing variants key', () {
      expect(
        () => validateCombatArchetypeSource(
          'arch.yaml',
          'archetypes:\n  - id: arch_bandit\n',
        ),
        failsWithSource('arch.yaml', 'missing required key "variants"'),
      );
    });

    test('rejects an empty variants list', () {
      expect(
        () => validateCombatArchetypeSource(
          'arch.yaml',
          'archetypes:\n  - id: arch_bandit\n    variants: []\n',
        ),
        failsWithSource(
          'arch.yaml',
          'archetypes[0].variants: must not be empty',
        ),
      );
    });

    test('rejects a variant with an unknown key', () {
      expect(
        () => validateCombatArchetypeSource(
          'arch.yaml',
          'archetypes:\n'
              '  - id: arch_bandit\n'
              '    variants:\n'
              '      - role_id: melee_brute\n'
              '        attack_token_kind: melee\n'
              '        hp_multiplier: 1.0\n'
              '        attack_multiplier: 1.0\n'
              '        defense_multiplier: 0.5\n'
              '        speed_multiplier: 1.0\n'
              '        crit_rate: 0.1\n',
        ),
        failsWithSource('arch.yaml', 'archetypes[0].variants[0]: unknown key'),
      );
    });

    test('rejects an unknown attack_token_kind', () {
      expect(
        () => validateCombatArchetypeSource(
          'arch.yaml',
          'archetypes:\n'
              '  - id: arch_bandit\n'
              '    variants:\n'
              '      - role_id: melee_brute\n'
              '        attack_token_kind: fire\n'
              '        hp_multiplier: 1.0\n'
              '        attack_multiplier: 1.0\n'
              '        defense_multiplier: 0.5\n'
              '        speed_multiplier: 1.0\n',
        ),
        failsWithSource(
          'arch.yaml',
          'archetypes[0].variants[0].attack_token_kind: unknown attack token kind "fire"',
        ),
      );
    });

    test('rejects a wrong-typed attack_token_kind', () {
      expect(
        () => validateCombatArchetypeSource(
          'arch.yaml',
          'archetypes:\n'
              '  - id: arch_bandit\n'
              '    variants:\n'
              '      - role_id: melee_brute\n'
              '        attack_token_kind: 3\n'
              '        hp_multiplier: 1.0\n'
              '        attack_multiplier: 1.0\n'
              '        defense_multiplier: 0.5\n'
              '        speed_multiplier: 1.0\n',
        ),
        failsWithSource(
          'arch.yaml',
          'archetypes[0].variants[0].attack_token_kind: expected a string',
        ),
      );
    });

    test('rejects a wrong-typed hp_multiplier', () {
      expect(
        () => validateCombatArchetypeSource(
          'arch.yaml',
          'archetypes:\n'
              '  - id: arch_bandit\n'
              '    variants:\n'
              '      - role_id: melee_brute\n'
              '        attack_token_kind: melee\n'
              '        hp_multiplier: strong\n'
              '        attack_multiplier: 1.0\n'
              '        defense_multiplier: 0.5\n'
              '        speed_multiplier: 1.0\n',
        ),
        failsWithSource(
          'arch.yaml',
          'archetypes[0].variants[0].hp_multiplier: expected a number',
        ),
      );
    });

    test('rejects a non-finite multiplier at the leaf path', () {
      expect(
        () => validateCombatArchetypeSource(
          'arch.yaml',
          validArchetypeYaml.replaceFirst(
            'hp_multiplier: 1.0',
            'hp_multiplier: .nan',
          ),
        ),
        failsWithSource(
          'arch.yaml',
          'archetypes[0].variants[0].hp_multiplier: must be finite',
        ),
      );
    });

    test('returns unmodifiable parsed collections', () {
      final source = validateCombatArchetypeSource(
        'arch.yaml',
        validArchetypeYaml,
      );
      expect(() => source.archetypes.clear(), throwsUnsupportedError);
      expect(
        () => source.archetypes.single.variants.clear(),
        throwsUnsupportedError,
      );
    });
  });

  group('validateCombatEncounterSource', () {
    test('parses a valid source into entries', () {
      final source = validateCombatEncounterSource(
        'enc.yaml',
        validEncounterYaml,
      );
      expect(source.sourceName, 'enc.yaml');
      final encounter = source.encounters.single;
      expect(encounter.id, 'enc_ambush');
      expect(encounter.spawnConfig.activeLimit, 4);
      expect(encounter.spawnConfig.reinforcementThreshold, 1);
      expect(encounter.spawnConfig.entryWarningTicks, 30);
      expect(encounter.spawnConfig.attackGraceTicks, 10);
      expect(encounter.tokenBudgets.melee, 3);
      expect(encounter.tokenBudgets.ranged, 2);
      expect(encounter.tokenBudgets.charge, 1);
      expect(encounter.tokenBudgets.support, 1);
      final entry = encounter.spawnEntries.single;
      expect(entry.entryId, 'brute_a');
      expect(entry.archetypeId, 'arch_bandit');
      expect(entry.roleId, 'melee_brute');
      expect(encounter.objective.kind, 'defeat_targets');
      expect(encounter.objective.idList, ['brute_a']);
      expect(encounter.objective.singleId, isNull);
      expect(encounter.objective.requiredTicks, isNull);
    });

    test('rejects an unknown top-level key', () {
      expect(
        () => validateCombatEncounterSource(
          'enc.yaml',
          'encounters: []\nwaves: 3\n',
        ),
        failsWithSource('enc.yaml', 'unknown key'),
      );
    });

    test('rejects a non-integer active_limit', () {
      expect(
        () => validateCombatEncounterSource(
          'enc.yaml',
          validEncounterYaml.replaceFirst(
            'active_limit: 4',
            'active_limit: 4.5',
          ),
        ),
        failsWithSource(
          'enc.yaml',
          'encounters[0].spawn_config.active_limit: expected an integer',
        ),
      );
    });

    test('rejects a wrong-typed reinforcement_threshold', () {
      expect(
        () => validateCombatEncounterSource(
          'enc.yaml',
          validEncounterYaml.replaceFirst(
            'reinforcement_threshold: 1',
            'reinforcement_threshold: one',
          ),
        ),
        failsWithSource(
          'enc.yaml',
          'encounters[0].spawn_config.reinforcement_threshold: expected an integer',
        ),
      );
    });

    test('rejects a missing token budget key', () {
      expect(
        () => validateCombatEncounterSource(
          'enc.yaml',
          validEncounterYaml.replaceFirst('      support: 1\n', ''),
        ),
        failsWithSource(
          'enc.yaml',
          'encounters[0].token_budgets: missing required key "support"',
        ),
      );
    });

    test('rejects empty spawn_entries', () {
      expect(
        () => validateCombatEncounterSource(
          'enc.yaml',
          validEncounterYaml.replaceFirst(
            '    spawn_entries:\n'
                '      - entry_id: brute_a\n'
                '        archetype_id: arch_bandit\n'
                '        role_id: melee_brute\n',
            '    spawn_entries: []\n',
          ),
        ),
        failsWithSource(
          'enc.yaml',
          'encounters[0].spawn_entries: must not be empty',
        ),
      );
    });

    test('rejects a spawn entry missing role_id', () {
      expect(
        () => validateCombatEncounterSource(
          'enc.yaml',
          validEncounterYaml.replaceFirst('        role_id: melee_brute\n', ''),
        ),
        failsWithSource(
          'enc.yaml',
          'encounters[0].spawn_entries[0]: missing required key "role_id"',
        ),
      );
    });

    test('rejects an unknown objective kind', () {
      expect(
        () => validateCombatEncounterSource(
          'enc.yaml',
          validEncounterYaml.replaceFirst(
            'kind: defeat_targets',
            'kind: capture_flag',
          ),
        ),
        failsWithSource(
          'enc.yaml',
          'encounters[0].objective.kind: unknown objective kind "capture_flag"',
        ),
      );
    });

    test('rejects an objective with an unknown key', () {
      expect(
        () => validateCombatEncounterSource(
          'enc.yaml',
          validEncounterYaml.replaceFirst(
            '      target_ids: [brute_a]\n',
            '      target_ids: [brute_a]\n      bonus: 1\n',
          ),
        ),
        failsWithSource('enc.yaml', 'encounters[0].objective: unknown key'),
      );
    });

    test('rejects defend_entity without required_ticks', () {
      expect(
        () => validateCombatEncounterSource(
          'enc.yaml',
          validEncounterYaml.replaceFirst(
            '      kind: defeat_targets\n      target_ids: [brute_a]\n',
            '      kind: defend_entity\n      entity_id: cart\n',
          ),
        ),
        failsWithSource(
          'enc.yaml',
          'encounters[0].objective: missing required key "required_ticks"',
        ),
      );
    });

    test('rejects a non-integer required_ticks', () {
      expect(
        () => validateCombatEncounterSource(
          'enc.yaml',
          validEncounterYaml.replaceFirst(
            '      kind: defeat_targets\n      target_ids: [brute_a]\n',
            '      kind: survive_duration\n      required_ticks: 10.5\n',
          ),
        ),
        failsWithSource(
          'enc.yaml',
          'encounters[0].objective.required_ticks: expected an integer',
        ),
      );
    });

    test('rejects empty target_ids', () {
      expect(
        () => validateCombatEncounterSource(
          'enc.yaml',
          validEncounterYaml.replaceFirst(
            'target_ids: [brute_a]',
            'target_ids: []',
          ),
        ),
        failsWithSource(
          'enc.yaml',
          'encounters[0].objective.target_ids: must not be empty',
        ),
      );
    });

    test('rejects a non-string target_ids entry', () {
      expect(
        () => validateCombatEncounterSource(
          'enc.yaml',
          validEncounterYaml.replaceFirst(
            'target_ids: [brute_a]',
            'target_ids: [1]',
          ),
        ),
        failsWithSource(
          'enc.yaml',
          'encounters[0].objective.target_ids[0]: expected a string',
        ),
      );
    });

    test('rejects a whitespace objective id at the leaf path', () {
      expect(
        () => validateCombatEncounterSource(
          'enc.yaml',
          validEncounterYaml.replaceFirst(
            'target_ids: [brute_a]',
            'target_ids: ["bad target"]',
          ),
        ),
        failsWithSource(
          'enc.yaml',
          'encounters[0].objective.target_ids[0]: must not contain whitespace',
        ),
      );
    });
  });

  group('validateCombatAssignmentSource', () {
    test('parses migrated and legacy assignments', () {
      final source = validateCombatAssignmentSource(
        'manifest.yaml',
        validAssignmentYaml,
      );
      expect(source.sourceName, 'manifest.yaml');
      expect(source.assignments, hasLength(2));
      final migrated = source.assignments[0];
      expect(migrated.stageId, 'stage_01');
      expect(migrated.migrationState, 'migrated');
      expect(migrated.encounterId, 'enc_ambush');
      final legacy = source.assignments[1];
      expect(legacy.stageId, 'stage_02');
      expect(legacy.migrationState, 'legacy');
      expect(legacy.encounterId, isNull);
    });

    test('rejects an unknown migration_state', () {
      expect(
        () => validateCombatAssignmentSource(
          'manifest.yaml',
          'stage_assignments:\n'
              '  - stage_id: stage_01\n'
              '    migration_state: partial\n'
              '    encounter_id: enc_ambush\n',
        ),
        failsWithSource(
          'manifest.yaml',
          'stage_assignments[0].migration_state: unknown migration state "partial"',
        ),
      );
    });

    test('rejects a legacy assignment carrying encounter_id', () {
      expect(
        () => validateCombatAssignmentSource(
          'manifest.yaml',
          'stage_assignments:\n'
              '  - stage_id: stage_01\n'
              '    migration_state: legacy\n'
              '    encounter_id: enc_ambush\n',
        ),
        failsWithSource('manifest.yaml', 'stage_assignments[0]: unknown key'),
      );
    });

    test('rejects a migrated assignment missing encounter_id', () {
      expect(
        () => validateCombatAssignmentSource(
          'manifest.yaml',
          'stage_assignments:\n'
              '  - stage_id: stage_01\n'
              '    migration_state: migrated\n',
        ),
        failsWithSource(
          'manifest.yaml',
          'stage_assignments[0]: missing required key "encounter_id"',
        ),
      );
    });

    test('rejects a null migrated encounter_id at the leaf path', () {
      expect(
        () => validateCombatAssignmentSource(
          'manifest.yaml',
          'stage_assignments:\n'
              '  - stage_id: stage_01\n'
              '    migration_state: migrated\n'
              '    encounter_id: null\n',
        ),
        failsWithSource(
          'manifest.yaml',
          'stage_assignments[0].encounter_id: expected a string',
        ),
      );
    });

    test('rejects an unknown top-level key', () {
      expect(
        () => validateCombatAssignmentSource(
          'manifest.yaml',
          'stage_assignments: []\nchapter: 1\n',
        ),
        failsWithSource('manifest.yaml', 'unknown key'),
      );
    });

    test('rejects an empty stage_assignments list', () {
      expect(
        () => validateCombatAssignmentSource(
          'manifest.yaml',
          'stage_assignments: []\n',
        ),
        failsWithSource(
          'manifest.yaml',
          'stage_assignments: must not be empty',
        ),
      );
    });

    test('rejects a non-string stage_id', () {
      expect(
        () => validateCombatAssignmentSource(
          'manifest.yaml',
          'stage_assignments:\n'
              '  - stage_id: 5\n'
              '    migration_state: legacy\n',
        ),
        failsWithSource(
          'manifest.yaml',
          'stage_assignments[0].stage_id: expected a string',
        ),
      );
    });
  });
}
