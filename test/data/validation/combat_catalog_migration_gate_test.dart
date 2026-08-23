import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_manifest_def.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_reference_index.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/defs/combat_enemy_archetype_def.dart';
import 'package:wuxia_idle/data/validation/combat_catalog_migration_gate.dart';

const _fixtureRoot = 'test/fixtures/phase2/combat/migration_gate';

Map<String, Object?> _fixture(String name) => Map<String, Object?>.from(
  jsonDecode(File('$_fixtureRoot/$name').readAsStringSync()) as Map,
);

List<String> _strings(Object? value) =>
    (value! as List<Object?>).map((entry) => entry! as String).toList();

List<Map<String, Object?>> _assignmentMaps(Map<String, Object?> fixture) =>
    (fixture['assignments']! as List<Object?>)
        .map((entry) => Map<String, Object?>.from(entry! as Map))
        .toList(growable: false);

CombatStageEncounterAssignment _assignment(Map<String, Object?> raw) {
  final state = switch (raw['state']) {
    'legacy' => CombatEncounterMigrationState.legacy,
    'migrated' => CombatEncounterMigrationState.migrated,
    final value => throw StateError('unsupported fixture state: $value'),
  };
  return CombatStageEncounterAssignment(
    stageId: raw['stageId']! as String,
    migrationState: state,
    encounterId: raw['encounterId'] as String?,
  );
}

CombatCatalogManifestDef _manifestFor(
  Iterable<CombatStageEncounterAssignment> assignments,
) {
  final assignmentList = assignments.toList(growable: false);
  final encounters = assignmentList
      .where((assignment) => assignment.encounterId != null)
      .map((assignment) => _encounter(assignment.encounterId!))
      .toList(growable: false);
  return CombatCatalogManifestDef(
    referenceIndex: _referenceIndex(),
    archetypes: encounters.isEmpty ? const [] : [_fixtureArchetype()],
    encounters: encounters,
    stageAssignments: assignmentList,
  );
}

CombatCatalogReferenceIndex _referenceIndex() => CombatCatalogReferenceIndex(
  entranceIds: const ['fixture_entrance'],
  positionIds: const ['fixture_position'],
  behaviorIds: const ['fixture_behavior'],
  attackSetIds: const ['fixture_attack_set'],
  attackTagIds: const ['fixture_attack_tag'],
  postureProfileIds: const ['fixture_posture'],
  dropGroupIds: const ['fixture_drop'],
  sfxGroupIds: const ['fixture_sfx'],
  visualVariantIds: const ['fixture_visual'],
);

CombatCatalogManifestDef _manifestFrom(
  Map<String, Object?> fixture, {
  bool reverseAssignments = false,
}) {
  final assignments = _assignmentMaps(fixture).map(_assignment).toList();
  return _manifestFor(reverseAssignments ? assignments.reversed : assignments);
}

CombatEnemyArchetypeDef _fixtureArchetype() => CombatEnemyArchetypeDef(
  id: 'fixture_archetype',
  variants: [
    CombatArchetypeVariant(
      roleId: 'fixture_role',
      attackTokenKind: CombatAttackTokenKind.melee,
      hpMultiplier: 1,
      attackMultiplier: 1,
      defenseMultiplier: 1,
      speedMultiplier: 1,
      attackSetId: 'fixture_attack_set',
      attackTagIds: const ['fixture_attack_tag'],
      postureProfileId: 'fixture_posture',
      dropGroupId: 'fixture_drop',
      sfxGroupId: 'fixture_sfx',
      visualVariantIds: const ['fixture_visual'],
    ),
  ],
);

CombatEncounterDef _encounter(String id) => CombatEncounterDef(
  id: id,
  spawnConfig: CombatEncounterSpawnConfig(
    activeLimit: 1,
    reinforcementThreshold: 0,
    entryWarningTicks: 0,
    attackGraceTicks: 0,
  ),
  tokenBudgets: CombatEncounterTokenBudgets(
    melee: 0,
    ranged: 0,
    charge: 0,
    support: 0,
  ),
  spawnEntries: [
    CombatEncounterSpawnEntry(
      entryId: 'entry_$id',
      archetypeId: 'fixture_archetype',
      roleId: 'fixture_role',
      entranceId: 'fixture_entrance',
      positionId: 'fixture_position',
      behaviorId: 'fixture_behavior',
    ),
  ],
  objectives: CombatObjectiveCompositionRef(
    completionRule: CombatObjectiveCompletionRule.all,
    clauses: [
      CombatObjectiveClauseRef(
        id: 'objective_$id',
        primitive: CombatDefeatTargetsRef(['target_$id']),
      ),
    ],
  ),
);

CombatCatalogMigrationCoverageException _captureFailure({
  required Iterable<String> knownStageIds,
  required Iterable<String> legacyAllowlist,
  required Iterable<String> legacyContentStageIds,
  required CombatCatalogManifestDef manifest,
}) {
  try {
    validateCombatCatalogMigrationCoverage(
      knownStageIds: knownStageIds,
      legacyAllowlist: legacyAllowlist,
      legacyContentStageIds: legacyContentStageIds,
      manifest: manifest,
    );
    fail('expected migration coverage validation to fail');
  } on CombatCatalogMigrationCoverageException catch (error) {
    return error;
  }
}

List<String> _issueKeys(CombatCatalogMigrationCoverageException error) => error
    .issues
    .map((issue) => '${issue.code.name}:${issue.stageId ?? '-'}')
    .toList(growable: false);

void main() {
  group('validateCombatCatalogMigrationCoverage', () {
    test('valid mixed fixture returns sorted immutable coverage', () {
      final fixture = _fixture('valid_mixed.json');
      final manifest = _manifestFrom(fixture);
      final knownStageIds = _strings(fixture['knownStageIds']);
      final legacyAllowlist = _strings(fixture['legacyAllowlist']);
      final legacyContentStageIds = _strings(fixture['legacyContentStageIds']);

      final report = validateCombatCatalogMigrationCoverage(
        knownStageIds: knownStageIds,
        legacyAllowlist: legacyAllowlist,
        legacyContentStageIds: legacyContentStageIds,
        manifest: manifest,
      );

      knownStageIds.clear();
      legacyAllowlist.clear();
      legacyContentStageIds.clear();

      expect(report.knownStageIds, [
        'stage_alpha_migrated',
        'stage_beta_migrated',
        'stage_eta_legacy',
        'stage_zeta_legacy',
      ]);
      expect(report.migratedStageIds, [
        'stage_alpha_migrated',
        'stage_beta_migrated',
      ]);
      expect(report.legacyStageIds, ['stage_eta_legacy', 'stage_zeta_legacy']);
      expect(report.legacyContentStageIds, [
        'stage_eta_legacy',
        'stage_zeta_legacy',
      ]);
      expect(report.knownStageCount, 4);
      expect(report.migratedStageCount, 2);
      expect(report.legacyStageCount, 2);
      expect(report.legacyContentStageCount, 2);
      for (final stageId in report.migratedStageIds) {
        expect(manifest.encounterForStage(stageId), isNotNull);
      }
      expect(
        () => report.knownStageIds.add('stage_mutation'),
        throwsUnsupportedError,
      );
      expect(
        () => report.legacyContentStageIds.add('stage_mutation'),
        throwsUnsupportedError,
      );
    });

    test('unknown omitted and stale routes fail in stable sorted order', () {
      final fixture = _fixture('invalid_coverage.json');
      final knownStageIds = _strings(fixture['knownStageIds']);
      final legacyAllowlist = _strings(fixture['legacyAllowlist']);
      final legacyContentStageIds = _strings(fixture['legacyContentStageIds']);

      final first = _captureFailure(
        knownStageIds: knownStageIds,
        legacyAllowlist: legacyAllowlist,
        legacyContentStageIds: legacyContentStageIds,
        manifest: _manifestFrom(fixture),
      );
      final reversed = _captureFailure(
        knownStageIds: knownStageIds.reversed,
        legacyAllowlist: legacyAllowlist.reversed,
        legacyContentStageIds: legacyContentStageIds.reversed,
        manifest: _manifestFrom(fixture, reverseAssignments: true),
      );

      expect(_issueKeys(first), [
        'unknownAssignmentStageId:stage_unknown_assignment',
        'missingStageAssignment:stage_missing',
        'unknownLegacyAllowlistStageId:stage_unknown_allowlisted',
        'unknownLegacyContentStageId:stage_unknown_content',
        'legacyStageMissingAllowlist:stage_beta_legacy',
        'legacyStageMissingAllowlist:stage_legacy_unallowlisted',
        'migratedStageInLegacyAllowlist:stage_migrated_allowlisted',
        'legacyStageMissingContent:stage_beta_legacy',
        'migratedStageHasLegacyContent:stage_migrated_allowlisted',
      ]);
      expect(_issueKeys(reversed), _issueKeys(first));
      expect(reversed.toString(), first.toString());
    });

    test('known stage ids must be non-empty unique and whitespace-free', () {
      final empty = _captureFailure(
        knownStageIds: const [],
        legacyAllowlist: const [],
        legacyContentStageIds: const [],
        manifest: _manifestFor(const []),
      );
      expect(_issueKeys(empty), ['emptyKnownStageIds:-']);

      final manifest = _manifestFor([
        CombatStageEncounterAssignment(
          stageId: 'stage_valid',
          migrationState: CombatEncounterMigrationState.legacy,
        ),
      ]);
      final dirty = _captureFailure(
        knownStageIds: const [
          '',
          'stage bad',
          'stage bad',
          'stage_valid',
          'stage_valid',
        ],
        legacyAllowlist: const ['stage_valid'],
        legacyContentStageIds: const ['stage_valid'],
        manifest: manifest,
      );
      expect(_issueKeys(dirty), [
        'invalidKnownStageId:',
        'invalidKnownStageId:stage bad',
        'duplicateKnownStageId:stage bad',
        'duplicateKnownStageId:stage_valid',
      ]);
    });

    test('legacy allowlist ids must be unique clean and known', () {
      final manifest = _manifestFor([
        CombatStageEncounterAssignment(
          stageId: 'stage_legacy',
          migrationState: CombatEncounterMigrationState.legacy,
        ),
      ]);

      final error = _captureFailure(
        knownStageIds: const ['stage_legacy'],
        legacyAllowlist: const [
          'stage_legacy',
          'stage_legacy',
          'stage bad',
          'stage_unknown',
        ],
        legacyContentStageIds: const ['stage_legacy'],
        manifest: manifest,
      );

      expect(_issueKeys(error), [
        'invalidLegacyAllowlistId:stage bad',
        'duplicateLegacyAllowlistId:stage_legacy',
        'unknownLegacyAllowlistStageId:stage_unknown',
      ]);
    });

    test('legacy content ids must be unique clean and known', () {
      final manifest = _manifestFor([
        CombatStageEncounterAssignment(
          stageId: 'stage_legacy',
          migrationState: CombatEncounterMigrationState.legacy,
        ),
      ]);

      final error = _captureFailure(
        knownStageIds: const ['stage_legacy'],
        legacyAllowlist: const ['stage_legacy'],
        legacyContentStageIds: const [
          'stage_legacy',
          'stage_legacy',
          'stage bad',
          'stage_unknown',
        ],
        manifest: manifest,
      );

      expect(_issueKeys(error), [
        'invalidLegacyContentStageId:stage bad',
        'duplicateLegacyContentStageId:stage_legacy',
        'unknownLegacyContentStageId:stage_unknown',
      ]);
    });

    test('duplicate manifest assignments fail closed before the gate', () {
      expect(
        () => _manifestFor([
          CombatStageEncounterAssignment(
            stageId: 'stage_duplicate',
            migrationState: CombatEncounterMigrationState.migrated,
            encounterId: 'encounter_alpha',
          ),
          CombatStageEncounterAssignment(
            stageId: 'stage_duplicate',
            migrationState: CombatEncounterMigrationState.migrated,
            encounterId: 'encounter_beta',
          ),
        ]),
        throwsArgumentError,
      );
    });

    test('all-migrated coverage allows an empty legacy allowlist', () {
      final manifest = _manifestFor([
        CombatStageEncounterAssignment(
          stageId: 'stage_migrated',
          migrationState: CombatEncounterMigrationState.migrated,
          encounterId: 'encounter_migrated',
        ),
      ]);

      final report = validateCombatCatalogMigrationCoverage(
        knownStageIds: const ['stage_migrated'],
        legacyAllowlist: const [],
        legacyContentStageIds: const [],
        manifest: manifest,
      );

      expect(report.legacyStageCount, 0);
      expect(report.migratedStageIds, ['stage_migrated']);
    });
  });
}
