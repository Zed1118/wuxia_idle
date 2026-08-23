/// Pure contract for choosing the legacy or migrated encounter path.
///
/// This resolver deliberately knows no stage data, loader, host, tuning,
/// objective, token, UI, reward, or save policy. Callers must provide the
/// already-derived structural facts for one content identifier.
enum Phase0aEncounterMigrationState { legacy, migrated }

/// Structural facts required by [Phase0aEncounterMigrationResolver].
final class Phase0aEncounterMigrationRequest {
  const Phase0aEncounterMigrationRequest({
    required this.contentId,
    required this.migrationState,
    required this.encounterCount,
    required this.hasLegacyContent,
  });

  final String contentId;
  final Phase0aEncounterMigrationState migrationState;
  final int encounterCount;
  final bool hasLegacyContent;
}

/// Resolves the only two accepted encounter migration shapes.
///
/// A legacy content ID must be explicitly allowlisted, have no encounter,
/// and still have legacy content. A migrated content ID must not be in that
/// allowlist, have exactly one encounter, and have no legacy content. Every
/// other combination is rejected before a caller can select a host path.
final class Phase0aEncounterMigrationResolver {
  Phase0aEncounterMigrationResolver({
    required Iterable<String> legacyContentIds,
  }) : _legacyContentIds = _freezeAllowlist(legacyContentIds);

  final Set<String> _legacyContentIds;

  Set<String> get legacyContentIds => _legacyContentIds;

  Phase0aEncounterMigrationState resolve(
    Phase0aEncounterMigrationRequest request,
  ) {
    final contentId = _checkedContentId(request.contentId);
    if (request.encounterCount < 0) {
      throw ArgumentError.value(
        request.encounterCount,
        'encounterCount',
        'must not be negative',
      );
    }

    final isAllowlisted = _legacyContentIds.contains(contentId);
    final matchesDeclaredShape = switch (request.migrationState) {
      Phase0aEncounterMigrationState.legacy =>
        isAllowlisted &&
            request.encounterCount == 0 &&
            request.hasLegacyContent,
      Phase0aEncounterMigrationState.migrated =>
        !isAllowlisted &&
            request.encounterCount == 1 &&
            !request.hasLegacyContent,
    };
    if (!matchesDeclaredShape) {
      throw ArgumentError.value(
        request,
        'request',
        'migrationState must match its allowlist, encounter count, and legacy content shape',
      );
    }
    return request.migrationState;
  }

  static Set<String> _freezeAllowlist(Iterable<String> ids) {
    final frozen = <String>{};
    for (final id in ids) {
      final checked = _checkedContentId(id);
      if (!frozen.add(checked)) {
        throw ArgumentError.value(id, 'legacyContentIds', 'must be unique');
      }
    }
    return Set<String>.unmodifiable(frozen);
  }

  static String _checkedContentId(String contentId) {
    if (contentId.trim().isEmpty || RegExp(r'\s').hasMatch(contentId)) {
      throw ArgumentError.value(
        contentId,
        'contentId',
        'must be non-empty and contain no whitespace',
      );
    }
    return contentId;
  }
}
