import 'dart:convert';

import '../defs/combat_catalog_manifest_def.dart';
import '../defs/combat_encounter_def.dart';

/// Stable categories emitted by [validateCombatCatalogMigrationCoverage].
enum CombatCatalogMigrationCoverageIssueCode {
  emptyKnownStageIds,
  invalidKnownStageId,
  duplicateKnownStageId,
  invalidLegacyAllowlistId,
  duplicateLegacyAllowlistId,
  duplicateStageAssignment,
  unknownAssignmentStageId,
  missingStageAssignment,
  unknownLegacyAllowlistStageId,
  legacyStageMissingAllowlist,
  migratedStageInLegacyAllowlist,
  migratedStageMissingEncounter,
  legacyStageHasEncounter,
}

/// One deterministic migration coverage failure.
final class CombatCatalogMigrationCoverageIssue
    implements Comparable<CombatCatalogMigrationCoverageIssue> {
  const CombatCatalogMigrationCoverageIssue(this.code, {this.stageId});

  final CombatCatalogMigrationCoverageIssueCode code;
  final String? stageId;

  @override
  int compareTo(CombatCatalogMigrationCoverageIssue other) {
    final codeOrder = code.index.compareTo(other.code.index);
    if (codeOrder != 0) return codeOrder;
    return (stageId ?? '').compareTo(other.stageId ?? '');
  }

  @override
  bool operator ==(Object other) =>
      other is CombatCatalogMigrationCoverageIssue &&
      code == other.code &&
      stageId == other.stageId;

  @override
  int get hashCode => Object.hash(code, stageId);

  @override
  String toString() {
    final id = stageId;
    return id == null ? code.name : '${code.name}(${jsonEncode(id)})';
  }
}

/// Aggregated fail-closed error with stable, immutable issue ordering.
final class CombatCatalogMigrationCoverageException implements Exception {
  CombatCatalogMigrationCoverageException(
    Iterable<CombatCatalogMigrationCoverageIssue> issues,
  ) : issues = List<CombatCatalogMigrationCoverageIssue>.unmodifiable(
        _sortedIssues(issues),
      ) {
    if (this.issues.isEmpty) {
      throw ArgumentError.value(issues, 'issues', 'must not be empty');
    }
  }

  final List<CombatCatalogMigrationCoverageIssue> issues;

  @override
  String toString() =>
      'CombatCatalogMigrationCoverageException(${issues.join(', ')})';
}

/// Immutable, deterministically ordered migration coverage summary.
final class CombatCatalogMigrationCoverageReport {
  CombatCatalogMigrationCoverageReport._({
    required Iterable<String> knownStageIds,
    required Iterable<String> migratedStageIds,
    required Iterable<String> legacyStageIds,
  }) : knownStageIds = List<String>.unmodifiable(_sortedIds(knownStageIds)),
       migratedStageIds = List<String>.unmodifiable(
         _sortedIds(migratedStageIds),
       ),
       legacyStageIds = List<String>.unmodifiable(_sortedIds(legacyStageIds));

  final List<String> knownStageIds;
  final List<String> migratedStageIds;
  final List<String> legacyStageIds;

  int get knownStageCount => knownStageIds.length;
  int get migratedStageCount => migratedStageIds.length;
  int get legacyStageCount => legacyStageIds.length;
}

/// Validates complete migration coverage without reading files or choosing
/// production routes.
///
/// The caller supplies the full known-stage universe, the temporary legacy
/// allowlist, and an already typed manifest. Validation fails closed unless:
/// - known ids and allowlist ids are clean and unique,
/// - manifest assignment ids equal the known-stage universe,
/// - legacy assignment ids equal the allowlist,
/// - every migrated stage resolves to an encounter.
///
/// All failures are aggregated and sorted independently of caller iteration
/// order. A successful report contains sorted, unmodifiable defensive copies.
CombatCatalogMigrationCoverageReport validateCombatCatalogMigrationCoverage({
  required Iterable<String> knownStageIds,
  required Iterable<String> legacyAllowlist,
  required CombatCatalogManifestDef manifest,
}) {
  final knownInput = List<String>.of(knownStageIds, growable: false);
  final allowlistInput = List<String>.of(legacyAllowlist, growable: false);
  final issues = <CombatCatalogMigrationCoverageIssue>{};

  if (knownInput.isEmpty) {
    issues.add(
      const CombatCatalogMigrationCoverageIssue(
        CombatCatalogMigrationCoverageIssueCode.emptyKnownStageIds,
      ),
    );
  }

  final known = _validatedIdSet(
    knownInput,
    invalidCode: CombatCatalogMigrationCoverageIssueCode.invalidKnownStageId,
    duplicateCode:
        CombatCatalogMigrationCoverageIssueCode.duplicateKnownStageId,
    issues: issues,
  );
  final allowlist = _validatedIdSet(
    allowlistInput,
    invalidCode:
        CombatCatalogMigrationCoverageIssueCode.invalidLegacyAllowlistId,
    duplicateCode:
        CombatCatalogMigrationCoverageIssueCode.duplicateLegacyAllowlistId,
    issues: issues,
  );

  final assignmentCounts = <String, int>{};
  for (final assignment in manifest.stageAssignments) {
    assignmentCounts.update(
      assignment.stageId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }

  for (final entry in assignmentCounts.entries) {
    if (entry.value > 1) {
      issues.add(
        CombatCatalogMigrationCoverageIssue(
          CombatCatalogMigrationCoverageIssueCode.duplicateStageAssignment,
          stageId: entry.key,
        ),
      );
    }
    if (!known.contains(entry.key)) {
      issues.add(
        CombatCatalogMigrationCoverageIssue(
          CombatCatalogMigrationCoverageIssueCode.unknownAssignmentStageId,
          stageId: entry.key,
        ),
      );
    }
  }

  for (final stageId in known) {
    if ((assignmentCounts[stageId] ?? 0) == 0) {
      issues.add(
        CombatCatalogMigrationCoverageIssue(
          CombatCatalogMigrationCoverageIssueCode.missingStageAssignment,
          stageId: stageId,
        ),
      );
    }
  }

  for (final stageId in allowlist) {
    if (!known.contains(stageId)) {
      issues.add(
        CombatCatalogMigrationCoverageIssue(
          CombatCatalogMigrationCoverageIssueCode.unknownLegacyAllowlistStageId,
          stageId: stageId,
        ),
      );
    }
  }

  final migrated = <String>{};
  final legacy = <String>{};
  for (final assignment in manifest.stageAssignments) {
    final stageId = assignment.stageId;
    if (!known.contains(stageId)) continue;

    switch (assignment.migrationState) {
      case CombatEncounterMigrationState.legacy:
        legacy.add(stageId);
        if (!allowlist.contains(stageId)) {
          issues.add(
            CombatCatalogMigrationCoverageIssue(
              CombatCatalogMigrationCoverageIssueCode
                  .legacyStageMissingAllowlist,
              stageId: stageId,
            ),
          );
        }
        if (assignment.encounterId != null) {
          issues.add(
            CombatCatalogMigrationCoverageIssue(
              CombatCatalogMigrationCoverageIssueCode.legacyStageHasEncounter,
              stageId: stageId,
            ),
          );
        }
      case CombatEncounterMigrationState.migrated:
        migrated.add(stageId);
        if (allowlist.contains(stageId)) {
          issues.add(
            CombatCatalogMigrationCoverageIssue(
              CombatCatalogMigrationCoverageIssueCode
                  .migratedStageInLegacyAllowlist,
              stageId: stageId,
            ),
          );
        }
        if (assignment.encounterId == null ||
            manifest.encounterForStage(stageId) == null) {
          issues.add(
            CombatCatalogMigrationCoverageIssue(
              CombatCatalogMigrationCoverageIssueCode
                  .migratedStageMissingEncounter,
              stageId: stageId,
            ),
          );
        }
    }
  }

  if (issues.isNotEmpty) {
    throw CombatCatalogMigrationCoverageException(issues);
  }

  return CombatCatalogMigrationCoverageReport._(
    knownStageIds: known,
    migratedStageIds: migrated,
    legacyStageIds: legacy,
  );
}

Set<String> _validatedIdSet(
  Iterable<String> ids, {
  required CombatCatalogMigrationCoverageIssueCode invalidCode,
  required CombatCatalogMigrationCoverageIssueCode duplicateCode,
  required Set<CombatCatalogMigrationCoverageIssue> issues,
}) {
  final valid = <String>{};
  final invalid = <String>{};
  final counts = <String, int>{};

  for (final id in ids) {
    counts.update(id, (count) => count + 1, ifAbsent: () => 1);
    if (!_isCleanId(id)) {
      invalid.add(id);
      continue;
    }
    valid.add(id);
  }

  for (final id in invalid) {
    issues.add(CombatCatalogMigrationCoverageIssue(invalidCode, stageId: id));
  }
  for (final entry in counts.entries) {
    if (entry.value > 1) {
      issues.add(
        CombatCatalogMigrationCoverageIssue(duplicateCode, stageId: entry.key),
      );
    }
  }
  return valid;
}

bool _isCleanId(String id) =>
    id.trim().isNotEmpty && !RegExp(r'\s').hasMatch(id);

List<String> _sortedIds(Iterable<String> ids) => <String>[...ids]..sort();

List<CombatCatalogMigrationCoverageIssue> _sortedIssues(
  Iterable<CombatCatalogMigrationCoverageIssue> issues,
) => <CombatCatalogMigrationCoverageIssue>[...issues.toSet()]..sort();
