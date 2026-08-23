import '../../features/battle/application/phase0a/'
    'phase0a_explicit_objective_event_source.dart';
import '../../features/battle/domain/phase0a/encounter_enemy_roster.dart';
import '../defs/combat_encounter_def.dart';

/// Maps explicit per-entry defeat-objective declarations onto exact runtime
/// roster actors.
///
/// The caller must declare every encounter entry exactly once, including
/// entries with no defeat projection. Target and commander payloads must
/// exactly close the encounter's typed defeat-objective references. Runtime
/// actor identity is obtained only from the roster's exact entry binding.
Phase0aExplicitObjectiveEventSource
mapCombatEncounterDefeatObjectiveEventSource(
  CombatEncounterDef definition,
  Phase0aEncounterRoster roster, {
  required Iterable<
    MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>
  >
  defeatProjectionEntries,
}) {
  final definitionEntryIds = {
    for (final entry in definition.spawnEntries) entry.entryId,
  };
  final rosterEntryIds = {
    for (final binding in roster.bindings) binding.entryId,
  };
  _requireExactCover(
    expected: definitionEntryIds,
    actual: rosterEntryIds,
    argumentName: 'roster',
    expectedLabel: 'definition',
    actualLabel: 'roster',
  );

  final materializedEntries = defeatProjectionEntries.toList(growable: false);
  final projectionsByEntryId =
      <String, List<Phase0aDefeatObjectiveProjection>>{};
  final duplicateEntryIds = <String>{};
  for (final declaration in materializedEntries) {
    final projections = List<Phase0aDefeatObjectiveProjection>.unmodifiable(
      declaration.value,
    );
    if (projectionsByEntryId[declaration.key] != null) {
      duplicateEntryIds.add(declaration.key);
    } else {
      projectionsByEntryId[declaration.key] = projections;
    }
  }
  if (duplicateEntryIds.isNotEmpty) {
    throw ArgumentError.value(
      duplicateEntryIds.toList()..sort(),
      'defeatProjectionEntries',
      'duplicate encounter entry id(s)',
    );
  }
  _requireExactCover(
    expected: definitionEntryIds,
    actual: projectionsByEntryId.keys.toSet(),
    argumentName: 'defeatProjectionEntries',
    expectedLabel: 'encounter',
    actualLabel: 'declarations',
  );

  final required = <_DefeatProjectionIdentity>{};
  for (final clause in definition.objectives.clauses) {
    final primitive = clause.primitive;
    if (primitive is CombatDefeatTargetsRef) {
      required.addAll(
        primitive.targetIds.map(
          (targetId) => (kind: _DefeatProjectionKind.target, id: targetId),
        ),
      );
    } else if (primitive is CombatDefeatCommanderRef) {
      required.add((
        kind: _DefeatProjectionKind.commander,
        id: primitive.commanderId,
      ));
    }
  }

  final declared = <_DefeatProjectionIdentity>{};
  final duplicateProjections = <_DefeatProjectionIdentity>{};
  for (final projections in projectionsByEntryId.values) {
    for (final projection in projections) {
      final identity = _identityOf(projection);
      if (!declared.add(identity)) duplicateProjections.add(identity);
    }
  }
  if (duplicateProjections.isNotEmpty) {
    throw ArgumentError.value(
      _sortedIdentityLabels(duplicateProjections),
      'defeatProjectionEntries',
      'duplicate typed defeat projection(s)',
    );
  }

  final missing = required.difference(declared);
  final foreign = declared.difference(required);
  if (missing.isNotEmpty || foreign.isNotEmpty) {
    throw ArgumentError.value(
      {
        'missing': _sortedIdentityLabels(missing),
        'foreign': _sortedIdentityLabels(foreign),
      },
      'defeatProjectionEntries',
      'typed defeat projections must exactly cover objective references',
    );
  }

  final projectionsByActorId =
      <String, Iterable<Phase0aDefeatObjectiveProjection>>{
        for (final entry in definition.spawnEntries)
          roster.bindingByEntryId(entry.entryId)!.actorId:
              projectionsByEntryId[entry.entryId]!,
      };
  return Phase0aExplicitObjectiveEventSource(
    roster: roster,
    defeatProjectionsByActorId: projectionsByActorId,
    externalProjectors: const [],
  );
}

enum _DefeatProjectionKind { target, commander }

typedef _DefeatProjectionIdentity = ({_DefeatProjectionKind kind, String id});

_DefeatProjectionIdentity _identityOf(
  Phase0aDefeatObjectiveProjection projection,
) {
  if (projection is Phase0aTargetDefeatProjection) {
    return (kind: _DefeatProjectionKind.target, id: projection.targetId);
  }
  final commander = projection as Phase0aCommanderDefeatProjection;
  return (kind: _DefeatProjectionKind.commander, id: commander.commanderId);
}

List<String> _sortedIdentityLabels(
  Iterable<_DefeatProjectionIdentity> identities,
) =>
    identities
        .map((identity) => '${identity.kind.name}:${identity.id}')
        .toList()
      ..sort();

void _requireExactCover({
  required Set<String> expected,
  required Set<String> actual,
  required String argumentName,
  required String expectedLabel,
  required String actualLabel,
}) {
  final missing = expected.difference(actual).toList()..sort();
  final extra = actual.difference(expected).toList()..sort();
  if (missing.isEmpty && extra.isEmpty) return;
  throw ArgumentError.value(
    {'missingFrom$actualLabel': missing, 'extraIn$actualLabel': extra},
    argumentName,
    'entry ids must exactly match $expectedLabel entry ids',
  );
}
