import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_migration_resolver.dart';

void main() {
  const legacyId = 'legacy_content';
  const migratedId = 'migrated_content';

  Phase0aEncounterMigrationRequest request({
    String contentId = migratedId,
    Phase0aEncounterMigrationState migrationState =
        Phase0aEncounterMigrationState.migrated,
    int encounterCount = 1,
    bool hasLegacyContent = false,
  }) => Phase0aEncounterMigrationRequest(
    contentId: contentId,
    migrationState: migrationState,
    encounterCount: encounterCount,
    hasLegacyContent: hasLegacyContent,
  );

  test('resolves the two accepted shapes', () {
    final resolver = Phase0aEncounterMigrationResolver(
      legacyContentIds: const [legacyId],
    );

    expect(
      resolver.resolve(
        request(
          contentId: legacyId,
          migrationState: Phase0aEncounterMigrationState.legacy,
          encounterCount: 0,
          hasLegacyContent: true,
        ),
      ),
      Phase0aEncounterMigrationState.legacy,
    );
    expect(
      resolver.resolve(request()),
      Phase0aEncounterMigrationState.migrated,
    );
  });

  test('requires explicit allowlist membership for legacy', () {
    final resolver = Phase0aEncounterMigrationResolver(
      legacyContentIds: const [],
    );

    expect(
      () => resolver.resolve(
        request(
          contentId: 'unlisted_legacy',
          migrationState: Phase0aEncounterMigrationState.legacy,
          encounterCount: 0,
          hasLegacyContent: true,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects wrong encounter counts and legacy-content flags', () {
    final resolver = Phase0aEncounterMigrationResolver(
      legacyContentIds: const [legacyId],
    );

    for (final invalid in <Phase0aEncounterMigrationRequest>[
      request(
        contentId: legacyId,
        migrationState: Phase0aEncounterMigrationState.legacy,
        encounterCount: 1,
        hasLegacyContent: true,
      ),
      request(
        contentId: legacyId,
        migrationState: Phase0aEncounterMigrationState.legacy,
        encounterCount: 0,
        hasLegacyContent: false,
      ),
      request(
        contentId: migratedId,
        encounterCount: 0,
        hasLegacyContent: false,
      ),
      request(contentId: migratedId, encounterCount: 1, hasLegacyContent: true),
      request(
        contentId: migratedId,
        encounterCount: 2,
        hasLegacyContent: false,
      ),
      request(
        contentId: legacyId,
        migrationState: Phase0aEncounterMigrationState.migrated,
        encounterCount: 0,
        hasLegacyContent: true,
      ),
      request(
        contentId: migratedId,
        migrationState: Phase0aEncounterMigrationState.legacy,
        encounterCount: 1,
        hasLegacyContent: false,
      ),
    ]) {
      expect(() => resolver.resolve(invalid), throwsArgumentError);
    }
  });

  test('rejects negative counts, blank IDs, and whitespace IDs', () {
    final resolver = Phase0aEncounterMigrationResolver(
      legacyContentIds: const [legacyId],
    );

    expect(
      () => resolver.resolve(request(encounterCount: -1)),
      throwsArgumentError,
    );
    for (final id in <String>[
      '',
      ' ',
      '\t',
      ' migrated_content',
      'migrated_content ',
    ]) {
      expect(
        () => resolver.resolve(request(contentId: id)),
        throwsArgumentError,
      );
    }
    expect(
      () =>
          Phase0aEncounterMigrationResolver(legacyContentIds: const ['bad id']),
      throwsArgumentError,
    );
  });

  test('freezes the allowlist defensively', () {
    final source = <String>[legacyId];
    final resolver = Phase0aEncounterMigrationResolver(
      legacyContentIds: source,
    );
    source.add('mutated_after_construction');

    expect(resolver.legacyContentIds, contains(legacyId));
    expect(
      resolver.legacyContentIds,
      isNot(contains('mutated_after_construction')),
    );
    expect(
      () => resolver.legacyContentIds.add('caller_mutation'),
      throwsUnsupportedError,
    );
    expect(
      () => Phase0aEncounterMigrationResolver(
        legacyContentIds: const [legacyId, legacyId],
      ),
      throwsArgumentError,
    );
  });
}
